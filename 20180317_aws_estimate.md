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

The other requirements "50K purchases where 80% during November and December" means that 40K purchases happen during the last two months. 40K happening in two months means, we can make an assumption that it will be 20K per months hence around 645 orders per day which would mean 

## 3. Price

## Conclusion