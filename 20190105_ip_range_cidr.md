# Define IP range for AWS EC2 inbound rules with CIDR notation

AWS EC2 security groups rules allow us to allow access to the EC2 instance on certain ports and for certain IP addresses. While ports and single IP address are easy to understand, the rules also support CIDR notation which is slightly more complex. But what CIDR notation allows us to do is to specify a rule for a range of IP addresses. Today we will see how CIDR notation works and how we can use it do define IP ranges.

## IP CIDR notation

The IP in CIDR notation is written as `x.x.x.x/y`. `x.x.x.x` being the IP address and `y` being the subnet mask.

The IP being a construct of four numbers of 8 bits, its binary representation can be seen as `1111 1111 . 1111 1111 . 1111 1111 . 1111 1111` or in decimal `255.255.255.255`. Now the IP can be anything from 0 to 255 for each of the four numbers, therefore it could be `192.168.10.15` which in binary is `1100 0000 . 1010 1000 . 0000 1010 . 0000 1111`. 

Similarly a subnet mask is represented as a series of 1. For example `255.255.0.0` being `1111 1111 . 1111 1111 . 0000 0000 . 0000 0000`. 

This would mean that an IP `192.168.10.15` with a subnet mask of `255.255.0.0` would mean that the subnet address is `192.168.0.0`, the result of IP `AND` subnet mask.
The CIDR notation is simply the number of one from left to right, being here `16` therefore the CIDR notation would be `192.168.10.15/16`.

Now that we understand the CIDR notation, let's see how we can use it to define IP range on AWS EC2 security group.

## Example for AWS EC2 security group

Taking back the previous example, we can define an inbound rule of `192.168.10.15/16`


For example `192.168.10.15/17`