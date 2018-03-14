# Estimating cloud infrastructure cost

Few weeks ago I was tasked to estimate a cloud architecture with limited requirements.
Today we will see the rules which can be followed in order to come up with a price tag. This post is composed by three parts:

 1. Defining the requirements
 2. Solution needs
 3. Price

## 1. Defining the requirements

Before starting any estimation, it is important to get at least one requirement. In this example we will invent a scenario, really close to what I had irl, whereby __we would be setting up a Christmas tree website__ with the following requirements.

- The trees are put to sale accross the whole year in advance
- We have about 50k purchases where 80% happens from November to December

The most important aspect to remember is that __estimates are estimates__. It will never be exact, even if it happens to be exact, we probably got lucky. __The goal of the estimates are to evaluate the magnitude of the price of an infrastructure whether the infrastructure would cost $100, $1000, $10K or $1M monthly__.

As we know that we will be deploying to Cloud environment, for example AWS, it already helps us by reducing the amount of possibilities.
Cloud providers have improved in term of pricing and provide a clear price per usage. Using this price we can estimate how much we would spend for our usage therefore the next step is to figure out what will be our usage.

Having large requirements is better than having none. Using that, we can deduce the implicit requirements which we will use to map it to our usage and calculate the cost.

In a web development estimation, what we need to consider are the main contributors to price. Those are:

- Hosting VMs
- Database VMs
- Bandwith
- Enterprise licenses of app and/or frameworks
- CDN
- Object storage
- Extra cloud services

Some of the contributors which would directly map to a price on AWS. Hosting VMs map to EC2s, bandwith maps to the outbound cost of VM conmunications, CDN maps to Cloudfront and object storage maps to a S3 storage.
Enterprise licenses are for tools like NService bus, Segment or similar which are paid solutions.
Extra cloud services could be services like elastic search.

Knowing this we have already scoped down to what we need to look into to get an estimate of the price.

## 2. Solution needs

Using back the requirements, __trees are put to sale accross the whole year__, we know that we will need to have the system up and running for the whole year. This implies that we can evaluated the cost of the VMs as if they will be running 24 hours per day.
The other requirements "50K purchases where 80% during November and December" means that 40K purchases happen during the last two months. 40K happening in two months means, we can make an assumption that it will be 20K per months hence around 645 orders per day, 

For a single country, we assume that all orders are spread across 6 hours during the day which results in 100 orders per hour.

_Now we know that we would need to be able to cater for 100 orders per hour._

Next we need to compute the storage of assets needed. For a shop-like site, we would have images of articles and advertisements.
Here we again assume about 20 variety of trees. If each image is a HD image of 12mb and we have maximum three pictures per tree, we would need around 1gb of storage. Including extra space for other content, _5gb of storage should be enough_.

Lastly for CDN purposes, we can assume a visit of 100K users for 40K purchases. If we assume that each users individually consume 100mb of content, _the CDN would deliver 10tb_.

For database usage, 5gb would be enough for a start to contain 40K orders history and data linked to it.

Lastely, the bandwith which needs to be paid is the outbound connection from the VM to the outside. In our case it is negligeable.

## 3. Price

From the assumptions we made, we had the following:

- Support for 100 orders per hour
- 5gb of asset storage
- 10tb of CDN
- 5gb of cloud storage

To support 100 orders per hour we need to be able to measure the complexity of our system to support a single order.
For instance if an order takes an hour, we would need 100 times the setup to match the requirement while if an order takes about 10 seconds, we can have 6 orders per minutes which means that we would be able to handle 360 orders per hour. Three time more than the requirement.
For such system, a t2.micro ec2 instance would be enough to support the website.

The storage of assets will be taken care of by a S3 storage.

The CDN is a negligeable price as 10tb can be seen as a small amount.

For cloud database storage, in AWS Aurora can be used to leverage the cloud benefits together with the relation aspect of the database.

Putting the prices together using the [AWS price calculator](http://calculator.s3.amazonaws.com/index.html).

| Name       | Unit price  | Monthly price |
|------------|-------------|-------------|
| t2.micro   | $0.0192 /month | $15         |
| S3 storage | -              | 
Aurora