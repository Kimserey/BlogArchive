# Custom grain storage for Microsoft.Orleans

Grains states in Orleans are stored in a grain storage. Orleans ships with multiple highly available storage implementation like Azure blob storage or AWS Dynamodb. Today we will see how we can implement our own grain storage which will store grains on [Minio](https://www.minio.io), an open source free private cloud storage.

1. Implement a simple blob storage abstraction and implementation with Minio
2. Implement grain storage interface
3. Register the grain storage

## 1. Implement a simple blob storage abstraction and implementation with Minio

```c#
internal interface IMinioStorage
{
    Task<bool> ContainerExits(string blobContainer);
    Task CreateContainerAsync(string blobContainer);
    Task<Stream> ReadBlob(string blobContainer, string blobName, string blobPrefix = null);
    Task UploadBlob(string blobContainer, string blobName, Stream blob, string blobPrefix = null, string contentType = null);
    Task DeleteBlob(string blobContainer, string blobName, string blobPrefix = null);
}
```

We create an abstraction with simple functions to check if a container exists, create a container, read a blob, upload a new blob and delete a blob.

Next we implement the interface using Minio dotnet.

```c#
internal class MinioStorage : IMinioStorage
{
    private readonly string _accessKey;
    private readonly string _secretKey;
    private readonly string _endpoint;
    private readonly string _containerPrefix;
    private readonly ILogger<MinioStorage> _logger;

    public MinioStorage(ILogger<MinioStorage> logger, string accessKey, string secretKey, string endpoint)

    {
        if (string.IsNullOrWhiteSpace(accessKey))
            throw new ArgumentException("Minio 'accessKey' is missing.");

        if (string.IsNullOrWhiteSpace(secretKey))
            throw new ArgumentException("Minio 'secretKey' is missing.");

        if (string.IsNullOrWhiteSpace(endpoint))
            throw new ArgumentException("Minio 'endpoint' is missing.");

        _accessKey = accessKey;
        _secretKey = secretKey;
        _endpoint = endpoint;
        _logger = logger;
    }

    public MinioStorage(ILogger<MinioStorage> logger, string accessKey, string secretKey, string endpoint, string containerPrefix)
        : this(logger, accessKey, secretKey, endpoint)
    {
        if (string.IsNullOrWhiteSpace(containerPrefix))
            throw new ArgumentException("Minio 'containerPrefix' is missing.");

        _containerPrefix = containerPrefix;
    }

    private MinioClient CreateMinioClient() => new MinioClient(_endpoint, _accessKey, _secretKey);

    private string AppendPrefix(string prefix, string value) => string.IsNullOrEmpty(prefix) ? value : $"{prefix}-{value}";

    private string AppendContainerPrefix(string container) => string.IsNullOrEmpty(_containerPrefix) ? container : AppendPrefix(_containerPrefix, container);

    private (MinioClient client, string bucket, string objectName) GetStorage(string blobContainer, string blobPrefix, string blobName)
    {
        var client = CreateMinioClient();

        return (client, AppendContainerPrefix(blobContainer), AppendPrefix(blobPrefix, blobName));
    }

    public Task<bool> ContainerExits(string blobContainer)
    {
        return CreateMinioClient().BucketExistsAsync(AppendContainerPrefix(blobContainer));
    }

    public Task CreateContainerAsync(string blobContainer)
    {
        return CreateMinioClient().MakeBucketAsync(blobContainer);
    }

    public async Task DeleteBlob(string blobContainer, string blobName, string blobPrefix = null)
    {
        var (client, bucket, objectName) =
            GetStorage(blobContainer, blobPrefix, blobName);

        await client.RemoveObjectAsync(bucket, objectName);
        }

    public async Task<Stream> ReadBlob(string blobContainer, string blobName, string blobPrefix = null)
    {
        var (client, bucket, objectName) =
            GetStorage(blobContainer, blobPrefix, blobName);

        var ms = new MemoryStream();

        await client.GetObjectAsync(bucket, objectName, stream =>
        {
            stream.CopyTo(ms);
        });

        ms.Position = 0;
        return ms;
    }

    public async Task UploadBlob(string blobContainer, string blobName, Stream blob, string blobPrefix = null, string contentType = null)
    {
        var (client, container, name) =
            GetStorage(blobContainer, blobPrefix, blobName);

        await client.PutObjectAsync(container, name, blob, blob.Length, contentType: contentType);
    }
}
```

The functions are straightforward and forward the input to the underlying Minio.dotnet implementation.

## 2. Implement grain storage interface

Next we can use the Minio storage in a grain storage.
We start by installing two packages:

```txt
Microsoft.Orleans.Core
Microsoft.Orleans.Runtime.Abstraction
```

Next we implement the two interfaces, `IGrainStorage` and `ILifecycleParticipant<ISiloLifecycle>`.
`IGrainStorage` defines the main storage functionality. I contains the Read/Write/Clear functions found in every storage.

```c#
public interface IGrainStorage
{
    Task ReadStateAsync(string grainType, GrainReference grainReference, IGrainState grainState);
    Task WriteStateAsync(string grainType, GrainReference grainReference, IGrainState grainState);
    Task ClearStateAsync(string grainType, GrainReference grainReference, IGrainState grainState);
}
```

`ILifecycleParticipant<ISiloLifecycle>` is used to register a function to lifecycle of the silo.

```c#
public interface ILifecycleParticipant<TLifecycleObservable>
    where TLifecycleObservable : ILifecycleObservable
{
    void Participate(TLifecycleObservable lifecycle);
}
```

Here is the full implementation of the grain storage which we will decompose next:

```c#
internal class MinioGrainStorage : IGrainStorage, ILifecycleParticipant<ISiloLifecycle>
{
    private readonly string _name;
    private readonly string _container;
    private readonly ILogger<MinioGrainStorage> _logger;
    private readonly IMinioStorage _storage;
    private readonly IGrainFactory _grainFactory;
    private readonly ITypeResolver _typeResolver;
    private JsonSerializerSettings _jsonSettings;

    public MinioGrainStorage(string name, string container, IMinioStorage storage, ILogger<MinioGrainStorage> logger, IGrainFactory grainFactory, ITypeResolver typeResolver)
    {
        _name = name;
        _container = container;
        _logger = logger;
        _storage = storage;
        _grainFactory = grainFactory;
        _typeResolver = typeResolver;
    }

    private string GetBlobNameString(string grainType, GrainReference grainReference)
    {
        return $"{grainType}-{grainReference.ToKeyString()}";
    }

    public async Task ClearStateAsync(string grainType, GrainReference grainReference, IGrainState grainState)
    {
        string blobName = GetBlobNameString(grainType, grainReference);

        try
        {
            _logger.LogTrace("Clearing: GrainType={0} Grainid={1} ETag={2} to BlobName={3} in Container={4}",
                grainType, grainReference, grainState.ETag, blobName, _container);

            await _storage.DeleteBlob(_container, blobName);
            grainState.ETag = null;

            _logger.LogTrace("Cleared: GrainType={0} Grainid={1} ETag={2} to BlobName={3} in Container={4}",
                grainType, grainReference, grainState.ETag, blobName, _container);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error clearing: GrainType={0} Grainid={1} ETag={2} BlobName={3} in Container={4} Exception={5}",
                grainType, grainReference, grainState.ETag, blobName, _container, ex.Message);

            throw;
        }
    }

    public async Task ReadStateAsync(string grainType, GrainReference grainReference, IGrainState grainState)
    {
        string blobName = GetBlobNameString(grainType, grainReference);

        try
        {
            _logger.LogTrace("Reading: GrainType={0} Grainid={1} ETag={2} to BlobName={3} in Container={4}",
                grainType, grainReference, grainState.ETag, blobName, _container);

            GrainStateRecord record;
            try
            {
                using (var blob = await _storage.ReadBlob(_container, blobName))
                using (var stream = new MemoryStream())
                {
                    await blob.CopyToAsync(stream);
                    record = ConvertFromStorageFormat(stream.ToArray());
                }
            }
            catch (BucketNotFoundException ex)
            {
                _logger.LogTrace("ContainerNotFound reading: GrainType={0} Grainid={1} ETag={2} to BlobName={3} in Container={4} Exception={5}",
                    grainType, grainReference, grainState.ETag, blobName, _container, ex.message);

                return;
            }
            catch (ObjectNotFoundException ex)
            {
                _logger.LogTrace("BlobNotFound reading: GrainType={0} Grainid={1} ETag={2} to BlobName={3} in Container={4} Exception={5}",
                    grainType, grainReference, grainState.ETag, blobName, _container, ex.message);

                return;
            }

            grainState.State = record.State;
            grainState.ETag = record.ETag.ToString();

            _logger.LogTrace("Read: GrainType={0} Grainid={1} ETag={2} to BlobName={3} in Container={4}",
                grainType, grainReference, grainState.ETag, blobName, _container);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reading: GrainType={0} Grainid={1} ETag={2} from BlobName={3} in Container={4} Exception={5}",
                grainType, grainReference, grainState.ETag, blobName, _container, ex.Message);

            throw;
        }
    }

    public async Task WriteStateAsync(string grainType, GrainReference grainReference, IGrainState grainState)
    {
        string blobName = GetBlobNameString(grainType, grainReference);

        int newETag = string.IsNullOrEmpty(grainState.ETag) ? 0 : Int32.Parse(grainState.ETag) + 1;
        try
        {
            _logger.LogTrace("Writing: GrainType={0} Grainid={1} ETag={2} to BlobName={3} in Container={4}",
                grainType, grainReference, grainState.ETag, blobName, _container);


            var record = new GrainStateRecord
            {
                ETag = newETag,
                State = grainState.State
            };

            using (var stream = new MemoryStream(ConvertToStorageFormat(record)))
            {
                await _storage.UploadBlob(_container, blobName, stream, contentType: "application/json");
            }

            grainState.ETag = newETag.ToString();

            _logger.LogTrace("Wrote: GrainType={0} Grainid={1} ETag={2} to BlobName={3} in Container={4}",
                grainType, grainReference, grainState.ETag, blobName, _container);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error writing: GrainType={0} Grainid={1} ETag={2} from BlobName={3} in Container={4} Exception={5}",
                grainType, grainReference, grainState.ETag, blobName, _container, ex.Message);

            throw;
        }
    }

    private byte[] ConvertToStorageFormat(object record)
    {
        var data = JsonConvert.SerializeObject(record, _jsonSettings);
        return Encoding.UTF8.GetBytes(data);
    }

    private GrainStateRecord ConvertFromStorageFormat(byte[] content)
    {
        var json = Encoding.UTF8.GetString(content);
        var record = JsonConvert.DeserializeObject<GrainStateRecord>(json, _jsonSettings);
        return record;
    }

    private async Task Init(CancellationToken ct)
    {
        _jsonSettings = OrleansJsonSerializer.UpdateSerializerSettings(OrleansJsonSerializer.GetDefaultSerializerSettings(_typeResolver, _grainFactory), true, true, null);

        if (!await _storage.ContainerExits(_container))
        {
            await _storage.CreateContainerAsync(_container);
        }
    }

    public void Participate(ISiloLifecycle lifecycle)
    {
        lifecycle.Subscribe(OptionFormattingUtilities.Name<MinioGrainStorage>(_name), ServiceLifecycleStage.ApplicationServices, Init);
    }

    internal class GrainStateRecord
    {
        public int ETag { get; set; }
        public object State { get; set; }
    }
}
```

Prior starting, we define a class which will be used to store the state in a blob:

```c#
internal class GrainStateRecord
{
    public int ETag { get; set; }
    public object State { get; set; }
}
```

Then we start first by implementing the `Clear` function:

```c#
public async Task ClearStateAsync(string grainType, GrainReference grainReference, IGrainState grainState)
{
    string blobName = GetBlobNameString(grainType, grainReference);

    try
    {
        await _storage.DeleteBlob(_container, blobName);
        grainState.ETag = null;
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error clearing: GrainType={0} Grainid={1} ETag={2} BlobName={3} in Container={4} Exception={5}",
            grainType, grainReference, grainState.ETag, blobName, _container, ex.Message);

        throw;
    }
}
```

It simply deletes the blob and set the grain state ETag to `null`.
Next we implement the `Read` function:

```c#
public async Task ReadStateAsync(string grainType, GrainReference grainReference, IGrainState grainState)
{
    string blobName = GetBlobNameString(grainType, grainReference);

    try
    {
        GrainStateRecord record;
        try
        {
            using (var blob = await _storage.ReadBlob(_container, blobName))
            using (var stream = new MemoryStream())
            {
                await blob.CopyToAsync(stream);
                record = ConvertFromStorageFormat(stream.ToArray());
            }
        }
        catch (BucketNotFoundException ex)
        {
            return;
        }
        catch (ObjectNotFoundException ex)
        {
            return;
        }

        grainState.State = record.State;
        grainState.ETag = record.ETag.ToString();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error reading: GrainType={0} Grainid={1} ETag={2} from BlobName={3} in Container={4} Exception={5}",
            grainType, grainReference, grainState.ETag, blobName, _container, ex.Message);

        throw;
    }
}
```

The read function reads from the blob storage and skips if bucket is not found or object is not found. Then we assign the data read to the `grainState`.
Lastly we implement the `Write` function:

```c#
public async Task WriteStateAsync(string grainType, GrainReference grainReference, IGrainState grainState)
{
    string blobName = GetBlobNameString(grainType, grainReference);

    int newETag = string.IsNullOrEmpty(grainState.ETag) ? 0 : Int32.Parse(grainState.ETag) + 1;
    try
    {
        var record = new GrainStateRecord
        {
            ETag = newETag,
            State = grainState.State
        };

        using (var stream = new MemoryStream(ConvertToStorageFormat(record)))
        {
            await _storage.UploadBlob(_container, blobName, stream, contentType: "application/json");
        }

        grainState.ETag = newETag.ToString();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error writing: GrainType={0} Grainid={1} ETag={2} from BlobName={3} in Container={4} Exception={5}",
            grainType, grainReference, grainState.ETag, blobName, _container, ex.Message);

        throw;
    }
}
```

The write function simply write the state provided to blob storage while updating the ETag.

## 3. Register the grain storage

```c#
internal static class MinioGrainStorageFactory
{
    internal static IGrainStorage Create(IServiceProvider services, string name)
    {
        IOptionsSnapshot<MinioGrainStorageOptions> optionsSnapshot = services.GetRequiredService<IOptionsSnapshot<MinioGrainStorageOptions>>();
        var options = optionsSnapshot.Get(name);
        IMinioStorage storage = ActivatorUtilities.CreateInstance<MinioStorage>(services, options.AccessKey, options.SecretKey, options.Endpoint);
        return ActivatorUtilities.CreateInstance<MinioGrainStorage>(services, name, options.Container, storage);
    }
}
```

```c#
public static class MinioSiloBuilderExtensions
{
    public static ISiloHostBuilder AddMinioGrainStorage(this ISiloHostBuilder builder, string providerName, Action<MinioGrainStorageOptions> options)
    {
        return builder.ConfigureServices(services => services.AddMinioGrainStorage(providerName, ob => ob.Configure(options)));
    }

    public static IServiceCollection AddMinioGrainStorage(this IServiceCollection services, string providerName, Action<OptionsBuilder<MinioGrainStorageOptions>> options)
    {
        options?.Invoke(services.AddOptions<MinioGrainStorageOptions>(providerName));
        return services
            .AddSingletonNamedService(providerName, MinioGrainStorageFactory.Create)
            .AddSingletonNamedService(providerName, (s, n) => (ILifecycleParticipant<ISiloLifecycle>)s.GetRequiredServiceByName<IGrainStorage>(n));
    }
}
```