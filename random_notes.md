# Audacity config to enhance voice

1. Noise reduction - Select empty noise and apply reduction to the whole track
2. Equalizer Add bass boost / Add treble boost
3. Normalize
4. Change tempo 20x

# Random notes from Machine Learning Projects for .NET Developers

Using distance to build a classifier, nearest neighbour classifier.

`K Nearest neighbour model`

`Laplace smoothing`

`Seq.scan` Returns intermediate states in a seq. Differentiate then fold only return last state.

__Supervised learning__
Regression classification.

__Unsupervised learning__
All we have is data. No particular questions.

Removing features can yield better result. Create additional features after understanding the data better.

__In regression model__
Use moving average to remove noise and make the line smoother.
Use most naive model as baseline. In this case bycicle average. Compute baseline error average.
Linear regression model. Composed by multiple variables times theta const which forms a linear combination.

__Gradient descent - supervised learning__
Use derivatives to find minimum.
Xk+1 = Xk - alpha * g'(Xk)

This is used to find the minimum as the slop is used to increase or decrease X in the right direction. When the slop is positive, it is removed from X so we go backward to find the minimum and if slop negative, we go upward.
We must theta while minimising the cost function.

Cost = (count - (θ0 + θ1 x time))^2

General formula to iterate for derivative can be used to find all theta
gof'=g'of x f'
Y =q0X0 +q1X1 +q2X2 +...+qN XN

Given Y and X0..k, when we estimate q0...qn, the cost represent the error between the real value Y and our calculation with the estimation q0...qn.
cost = (Y - (q0X0 +q1X1 +q2X2 +...+qN XN))^2
cost' = 2 (Y - (q0X0 +q1X1 +q2X2 +...+qN XN)) * (- Xk)
cost' = 2Xk ((q0X0 +q1X1 +q2X2 +...+qN XN) - Y)

__Batch gradient descent__
Instead of taking the cost for one observation, calculation the cost for the whole dataset of observations.

cost(q0,q1) = 1/N [ (obs1.Cnt - (q0 + q1 x obs1.Instant))^2 + ... + (obsN.Cnt - (q0 + q1 x obsN.Instant))^2 ]
Average of the cost for each observation.

K means clustering algorithm - unsupervised learning
Place centroid and update centroid position to be average of the data inside the zone. Update centroid until stable.
When features aren't on the same scale, using an euclidean distance is not good as one feature might take priority over others due to the difference of scale which affect the positions of the centroids. In this case, rescaling is important. There are multiple ways to rescale data. In the book he shows how to rescale by size or also rescale by tag use which makes sense for stackoverflow so that the data only reflect a percentage of usage based on the most used tag by the user.

K minimizing with AIC. Put penality on addition of centroids + 2*m*k to the RSS residual sum of square. RSS is the sum of all square distance from centroid. It is used to compute the error.

Have a baseline or benchmark which is the easiest prediction usually average that one could make and compare your result to that. If you are lower then that, something is wrong.

__Tree with Decision stump__
Information gain

gain = total entropy - (proba of having this group 1 * entropy for that group of the group 1 + ... + p n * entropy n)
gain = total entropy - average entropy of the groups

Measures the gain by subtracting the total entropy (beginning entropy) by the sum of all the entropy of each groups after we break by the feature the sample set into smaller sample set.
Allows to take decision on which decision stump to go for.

__K-fold__
Divide sample set into k sample sets and do a rolling validation with each sample set being used as training set and validation.

__Random forest__
Train many trees selecting random features and using possibly duplicated random training data and get the majority vote.

__Reinforcement learning__
Make decision based on experience
Learn from new experience

__Q-learning__
Include next step gain as well

__Epsilon-learning__
Element on randomness. Every turn throw the dice before taking a thought decision or random decision

__Logistic regression__
Take a regression model and transforms it to a value from 0 to 1
Better than nearest neighbour to share the model because we approximate to a function and just need to pass the function around.

Binary classifier with One vs One and One vs All
