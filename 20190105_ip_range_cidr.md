# Define IP range for AWS EC2 inbound rules with CIDR notation

AWS EC2 security groups rules allow us to allow access to the EC2 instance on certain ports and for certain IP addresses. While ports and single IP address are easy to understand, the rules also support CIDR notation which is slightly more complex. But what CIDR notation allows us to do is to specify a rule for a range of IP addresses. Today we will see how CIDR notation works and how we can use it do define IP ranges in three parts:

1. IP CIDR notation
2. Example for AWS EC2 security group
3. Restrict on ISP

## 1. IP CIDR notation

The IP in CIDR notation is written as `x.x.x.x/y`. `x.x.x.x` being the IP address and `y` being the subnet mask.

The IP being a construct of four numbers of 8 bits, its binary representation can be seen as `1111 1111 . 1111 1111 . 1111 1111 . 1111 1111` or in decimal `255.255.255.255`. Now the IP can be anything from 0 to 255 for each of the four numbers, therefore it could be `192.168.10.15` which in binary is `1100 0000 . 1010 1000 . 0000 1010 . 0000 1111`. 

Similarly a subnet mask is represented as a series of 1. For example `255.255.0.0` being `1111 1111 . 1111 1111 . 0000 0000 . 0000 0000`. 

This would mean that an IP `192.168.10.15` with a subnet mask of `255.255.0.0` would mean that the subnet address is `192.168.0.0`, the result of IP `AND` subnet mask.
The CIDR notation is simply the number of one from left to right, being here `16` therefore the CIDR notation would be `192.168.10.15/16`.

Now that we understand the CIDR notation, let's see how we can use it to define IP range on AWS EC2 security group.

## 2. Example for AWS EC2 security group

Taking back the previous example, we can define an inbound rule of `192.168.10.15/17`.

![example](https://raw.githubusercontent.com/Kimserey/BlogArchive/master/img/20190105_cidr.md/ip_range.PNG)

We seen in 1) that the representation of `192.168.10.15` is `1100 0000 . 1010 1000 . 0000 1010 . 0000 1111`.
`17` being the number of 1, we can conlude that the subnet mask is `1111 1111 . 1111 1111 . 1000 0000 . 0000 0000`.
Now if we `AND` both, we find that the subnet is:

| | | | | |
| - | - | - | - | - |
| IP   | 1100 0000 | 1010 1000 | 0000 1010 | 0000 1111 |
| MASK | 1111 1111 | 1111 1111 | 1000 0000 | 0000 0000 |
| SUBNET | 1100 0000 | 1010 1000 | 0--- ---- | ---- ---- |
| -      | 192       | 168       | 0 - 127  | - | 

Because the mask is `17`, the third number last bit must match the mask which is `0` therefore constrains the IP to `0-127`. This allows subnet to be subnets to be divided even further and in our case it allows us to constrain the IP address in a granular fashion.

Therefore this rule will then match IP addresses from `192.168.0.0` to `192.168.127.255` which is a range of `32768` hosts `128 (0-127) * 256 (0-255)`.

## 3. Restrict on ISP

Internet service provider can be a good way to restrict IP addresses as it _kind of_ provides a range of IPs that are _kind of_ in the same geolocation. For example, we can restrict our website to only viewers in Ireland using Vodafone by finding Vodafone IP range. We can get that from websites like [dbip](https://db-ip.com/).

We can then restrict our website to `109.76.0.0/16, 109.77.0.0/16, 109.79.0.0/16`, that would cover about 240,000 users which according to `db-ip` is about half of the known IP addresses for Vodafone in Ireland under `VODAFONE-IRELAND-ASN`.

## Conclusion

Today we saw how IP CIDR notation can be used to provide access to a subset of IP addresses. We started by looking at what IP CIDR notation was and what the bit representation of an IP was. We then moved to look into a concrete example and how we could create an IP CIDR notation to allow an IP range on a EC2 inbound rule and lastly we concluded by looking at how we could figure out how to allow a subset of users from a particular ISP. Hope you liked this post, see you on the next one!