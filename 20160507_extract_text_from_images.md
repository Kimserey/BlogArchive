# Extract text from images in F# - OCR'ing my receipts!

Last week [I talked about how I used Deedle to make some basic statistics on my expenses.](https://kimsereyblog.blogspot.co.uk/2016/04/a-primer-on-manipulating-data-frame.html) 
Using my bank statements, I showed how to categorize, group, sum and sort expenses so that it would bring a better visibility.

Even though it was already very helpful, I realised that instead of checking each transaction as a whole,
it would be better to track individual items purchased.
A lot of expenses tracker work this way already but it takes too much time.
The idea of keying every expense was not considerable.
I needed a better way - __Extract text from the receipt image__.

Today I will share with you how I built a webapp which takes an image and extract the text from the image.
You can view the [site live here](arche.cloudapp.net:9000) and as usual the source code is available on [my github here](https://github.com/Kimserey/OcrApp).

This post is composed by four steps which are the steps I took in order to understand how to boot up a prototype.

1. Tesseract OCR - .NET
2. Dont' try to train Tesseract
3. Use ImageMagick to clean the image and try again
4. Boot up a OWIN selfhost WebSharper Client-Server app

## 1. Use Tesseract OCR - .NET

I had no idea about how I would proceed so I started to search for tools to "read text from images".
A quick search came out with lot of results containing the term OCR - _Optical Character Recognition_.
One of the most popular OCR library available on .NET at the moment is [Tesseract](https://github.com/charlesw/tesseract).

__Tesseract__ has some trained machine learning algorithms which detect text in images.
It has already been trained on lots of common fonts with its [training data available here](https://github.com/tesseract-ocr/tessdata).

To start using it, we need to download it from Nuget.
```
Install-Package Tesseract
```
Get the training data and place it into a [`/tessdata`](https://github.com/tesseract-ocr/tessdata/releases/tag/3.04.00) folder which is set to be copied to output.
With the following code, we can now extract the data from an image:

```
use engine = new TesseractEngine(@"./tessdata", "eng", EngineMode.Default))
use img = Pix.LoadFromFile(__SOURCE_DIRECTORY__ + "/img/original.jpg"))
use page = engine.Process(img)
printfn "%s" (page.GetText())
printfn "Confidence: %.4f" (page.GetMeanConfidence())
```

Remember that the text extracted will never be totally perfect.
Just accept it :).

## 2. Dont' try to train Tesseract

When I first started to look at Tesseract and tried to read the text from a receipt image, it did not work well.
The text was not accurate.
Knowing that Tesseract could be trained, I jump onto trying to train it to read my image.

__That was a mistake.__

Tesseract has been in development for a long time already and has been trained to recognize lots of fonts already.
The problem was not in it not being trained enough but in my image being of very poor quality.

If you need to read an unknown font or even harder, read a handwritten text then you will have to train Tesseract.
But it won't be a piece of cake :).

Lucky me after few hours of search I found [ImageMagick](https://www.imagemagick.org/script/index.php).

## 3. Clean the image with ImageMagick and try again

ImageMagick is an amazing library which contains an enormous amount of functions to manipulate images.
It can be used in command line but there is also a .NET wrapper to use it.
I am using ImageMagick with TextCleaner to remove all the noise from the image and keep only the text.

```
Install-Package Magick.NET-Q16-AnyCPU
Install-Package FredsImageMagickScripts.TextCleaner
```

`FredsImageMagickScripts` is a set of C# files which uses `ImageMagick`.
So I've added a C# project to add the scripts which I then referenced into my F# project.

![project](https://2.bp.blogspot.com/-8S0mxPS5cP0/Vy2ynbj0BLI/AAAAAAAAAG8/SH1Bjq1RrHo28k3nMCZMNfUbRSOTakZlgCKgB/s320/Screen%2BShot%2B2016-05-07%2Bat%2B10.13.23.png)

Textcleaner is simple to use, all you need to do is instantiate a `TextCleanerScript` and pass it a `MagickImage`.

```
let cleanImg imgStream =
    use img = new MagickImage(new Bitmap(Bitmap.FromStream imgStream))
    let cleaner = TextCleanerScript()
    
    // A lot of options can be set on the cleaner
    // cleaner.FilterOffset <- 10.
    // cleaner.SmoothingThreshold <- 5.
    
    let cleaned = cleaner.Execute(img).ToBitmap()
    cleaned
```

Here's the image before:

![original](https://cdn.rawgit.com/Kimserey/OcrApp/master/original.jpeg)

Here's the image after cleaning:

![cleaned](https://cdn.rawgit.com/Kimserey/OcrApp/master/cleaned.jpeg)

Definitely not the best cleaning, a lot of configurations are available.
I only used the default configuration.
Using the cleaning image, we can now pass it through Tesseract and extract the text with a much better mean confidence.

```
let getText imgStream =
    // Use ImageMagick to process image before OCR
    // 
    use img = new MagickImage(new Bitmap(Bitmap.FromStream imgStream))
    let cleaner = TextCleanerScript()
    let cleaned = cleaner.Execute(img).ToBitmap()

    // Use processed image with Tesseract OCR to get text
    //
    use engine = new TesseractEngine("tessdata", "eng")
    use img    = PixConverter.ToPix cleaned
    use page   = engine.Process img
    page.GetText()
```

Here's the result without cleaning the text:
```
V MR BAC FOR LIFE
P/EXPRESS MARGHERITA
P/EXPRESS AMERICAN
HERTA CHICKEN FRANKS
NR CHICK/VEG BROTH
NR RSTD MUSHRM PATE
NR BRTSH HAM W/THIN
RACHEL'S APPLE & CIN
HEINZ BAKED BEANS
HEINZ BAKED BEANS
HEINZ BAKED BEANS
HEINZ BAKED BEANS
WHITE BUTTER MUFFINS
Reduced item:
NARBURTUNS SEEDED
*1: Pizza expresz
```

And here's the result with the text cleaned:
```
V HR BAG FOR LIFE
P/EXPRESS MARGHERITA
P/EXPRESS AMERICAN
HERTA CHICKEN FRANKS
WR CHICK/VEG BRDTH
NR RSTD MUSHRM PATE
NR BRTSH HAM W/THIN
RACHEL'S APPLE & CIN
HEINZ BAKED BEANS
HEINZ BAKED BEANS
HEINZ BAKED BEANS
HEINZ BAKED BEANS
WHITE BUTTER MUFFINS
Reduced item:
WARBURTONS SEEDED
** Pizza expresZ For 28 **
14 items
BALANCE DUE
```

We can see that the result has improved as the last part could not be read from the original image, probably due to the shadow.

## 4. Boot up a OWIN selfhost WebSharper Client-Server app

This part isn't necessary but I thought I would put together a tool to directly visualise the effect of cleaning versus not cleaning the text.

The site is accessible here [http://arche.cloudapp.net:9000](http://arche.cloudapp.net:9000)

I am using cropbox - A JS library to upload image and crop directly in the browser. The source is available [here](https://github.com/Kimserey/OcrApp/blob/master/Selfhost/Cropbox.fs).
If you need to know how to use JS libraries with F# and creating bindings under WebSharper, you can read my previous post - [External JS library with Websharper in F#](https://kimsereyblog.blogspot.co.uk/2016/01/external-js-library-with-websharper-in-f.html).

And I am also using a Bootstrap with some helper functions created. The source is available [here](https://github.com/Kimserey/OcrApp/blob/master/Selfhost/Bootstrap.fs).
If you want to know more about it you can read my previous post - [Method chaining for Bootstrap](https://kimsereyblog.blogspot.co.uk/2016/02/method-chaining-for-bootstrap.html)

Using a simple `RPC`, we can call the functions that we created to use ImageMagick and Tesseract and return the text and confidence.

```
[<Rpc>]
let getText (imageBase64String: string): Async<string list * float> = 
    use memory = new MemoryStream(Convert.FromBase64String imageBase64String)
    let OCR.TextResult txt, OCR.Confidence confidence = OCR.getText memory
    async.Return (txt.Split '\n' |> Array.toList, float confidence)
``` 

And finally everything is booted on [a OWIN selfhost](https://github.com/Kimserey/OcrApp/blob/master/Selfhost/Program.fs#L120).

![preview](https://cdn.rawgit.com/Kimserey/OcrApp/master/Screen%20Shot%202016-05-07%20at%2002.21.07.png)

## Conclusion

This post wasn't so much about the coding. I wanted to share with you the tools available to do OCR.
And more importantly I wanted to show how quick and easy it was to put a workable project together with WebSharper and F#.
There is still a lot of work to do to get the text correct before it can be really useful.
Textcleaner can be configured better to remove more noise and make the text clearer.
And the text still needs to be processed to be useful.
I will be doing it next so let me know if you like this topic.
Anyway I hope this post gave you some ideas. If it did let me know on twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam)!
See you next time!
