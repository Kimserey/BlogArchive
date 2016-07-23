# Approximate your spending pattern using Gradient descent in FSharp

The advantage of tracking your expenses is that you can compare each month and check if you saved more or less money than the previous month.
Another interesting information is to __know how fast you are spending your money__.
Checking how fast you spend your money can give you indication on whether you are likely to be out or within budget at the end of the month.

The easiest way to check that is to plot the daily cumulated sum of your expenses and compare each month.
I have been doing this for the past few months and it worked pretty well but I realised that the cumulated sum is not always nice to look at. It looks like incremental steps which is not so pleasing to the eye.
Staring at more than incremental steps curves looks quite messy.

__The goal is to be able to be able to understand your financial situation in a glance, without having to spend more than one second a the plot.__

This is were having straight lines is more practical.
Straight lines are much more pleasing to the eye than incremental steps so it would be much nicer if I could transform supermarket expenses montly curves to straight lines but __how do I transform points to a straight line?__

Lucky me there are plenty of algorithms to build approximation for straight lines. 
__Gradient descent__ is one of those. So today I will explain the steps which needs to be taken to achieve a nice approximation.

![approximation](https://raw.githubusercontent.com/Kimserey/DataExpenses/master/img/approximation_animation.gif)

Today I would like to share how you can use __Gradient descent__ to approximate your spending pattern with a straight line.
This post is composed by three parts:

1. What is Gradient descent
2. Cost function and algorithm
3. Apply to real life data with F#


## 1. What is Gradient descent

The equation which governs straight lines is the following:

```
y = a * x + b
```

It is composed by a result value `y` which is expessed in fonction of a value `x` multiplied by a coefficient `a` and adding an offset value `b`.
This is a definition of a straigh line.

__Why do we go through all that trouble to get a straight line?__

As you see from the plot in the introduction, real life data like supermarket expenses aren't consistant.
Therefore it is hard to make any estimation apart from visual estimation.
What we want is to reduce that function to the most simplistic function __without having to much error__.
If we manage to reduce the curve to a first degree equation (straight line), we will be able to approximate on each day how much the expenses will be.
Therefore using this approximation can help us, when we are in the middle of the month, to approximate the rest of the month and check whether we are heading to the right direction.

__What is Gradient descent?__

Our goal is to find `y = a * x + b`. In this equation the only unknown are the coefficients `a` and `b`.
We could take any `a` and `b` but taking random values would not yield good result... or would it?
Well __we can't know what is good and what is bad unless we have a way to measure it__.

To estimate the error we will use the __Least square estimate__, we will call it the __cost function__.
Since the goal is to find the best approximation, it means that __we must minimize the cost function__ - this is what Gradient descent allows us to do.

__Gradient descent allows us to find `a` and `b` which minimize the cost function, therefore gives the best estimate.__

## 2. Cost function and algorithmn

The cost function is expressed by the following formula:

E = SQUARE ROOT (SIGMA (y' - y)2) / n

LSE calculates the `average squared error`:
 - `error` because `y' - y` represents the difference between the estimated value and the real value.
 - `average` because it sums all the errors and divides the result by the number of value.
 - `squared` because it takes the square of each error and apply a square root at the end. 
The square penalizes the error, the larger the difference is, the bigger the error will be.

If we replace y' by our function, we will get:

e = S(S(a * x + b - y)2 / n

__Gradient descent__

In order to find the best `a` and `b` tuple which minimises the cost function.
We will apply Gradient descent.

In simple scenarios like this supermarket expenses, Gradient descent is very efficient.
It allows us to converge toward a minima by using the __derivatives of the cost function__.
A derivative on a certain point of the function is the `slope` of the tangeant on that particular point.
`Gradient` is another word for `slope`.

This is the key secret of Gradient descent, it uses the slope to define its direction:
 - When the slope is positive, the function is going upward therefore the minima is on the left 
 - When the slope is negative, the function is going downward therefore the minima is on the right

Using this two definitions, we can establish the following algorithm to converge to the minima (1):

```
a_next = a - alpha * de/da
b_next = b - alpha * de/db
```

This is the core of Gradient descent, `de/da` and `de/db` are respectively the derivatives of the cost function in function of `a` and `b`.
On each step, we calculate the derivatives and update `a` and `b`.

With a bit of derivatives calculus, we can get `de/da` and `de/db`.
This is basically a gof formula where `gof' = g'of * f'` where `g = x2 => g' = 2x` and `f = (a * x + b - y) => f'a = x | f'b = 1`.

de/da = 2/n SIGMA x * (a * x + b - y)
de/db = 2/n SIGMA (a * x + b - y)

_`a` and `b` usually appear as theta1 and thetha0_.

`alpha` is the learning rate. It represents the step to take between each iterations.
This constant is __very__ important as it directly affects the results.
In order to find the `alpha` which suits your function, ry to see how big are the derivatives and compensate the alpha to reduce the step taken or increase it if too small.

So we will iterate over the algorithm to get the perfect `a` and `b`.

__When do we stop?__

What worked for me was to set a definite number of iterations.
Using a definite number is easy because you know how many iterations it will take to reach the result therefore you don't risk to be stuck in an infinite loop.

Wonderful, you now know everything about the gradient descent!

## 3. Apply to real life data with F#

Let's start first by defining the settings of the Gradient descent.

```
type Settings = {
    LearningRate: float
    Dataset: List<float * float>
    Iterations: int
}
```

We have the learning rate `alpha`, the dataset a list of (x, y) and the number of iterations.

From #2, we learnt that to compute Gradient descent we only need to calculate `a` and `b`.
And to compute `a` and `b` we will iterate n time over the Gradient descent formula (1).


In the calculation of the thetha0 and thetha1, the only difference is the derivative calculation.
Even within the derivative calculation, the only difference is the inner derivative.
Knowing that we can define a generic function to calculate the next theta.

```
let nextThetha innerDerivative (settings: Settings) thetha =
    let sum =
        [0..settings.Dataset.Length - 1]
        |> List.map (fun i -> settings.Dataset.[i])
        |> List.map (fun (x, y) -> innerDerivative x y)
        |> List.sum

    thetha - settings.LearningRate * ((1./float settings.Dataset.Length) * sum)
```

And finally we can now iterate n number of time and calculate the thetas.

```
let estimate settings =
    [0..settings.Iterations]
    |> List.scan (fun thethas _ -> 
        match thethas with
        | thetha0::thetha1::_ ->

            let thetha0 = 
                nextThetha (fun x y -> thetha0 + thetha1 * x - y) settings thetha0
            
            let thetha1 = 
                nextThetha (fun x y -> (thetha0 + thetha1 * x - y) * x) settings thetha1
            
            [ thetha0; thetha1 ]
        
        | _ -> failwith "Could not compute next thethas, thethas are not in correct format.") [0.; 0.]
```

`List.scan` executes a `fold` and returns each iterations. 
`estimate` will return the list of all thethas calculated on each iteration.

```
let createModel settings =
    let interationSteps = estimate settings

    match List.last interationSteps with
    | thetha0::thetha1::_ as thethas->
        { Estimate = fun  x -> thetha0 + thetha1 * x
            Cost = Cost.Compute(settings.Dataset, thethas)
            Thethas = thethas
            ThethaCalculationSteps = ThethaCalculationSteps interationSteps }
    | _ -> failwith "Failed to create model. Could not compute thethas."
```

Here the full `GradientDescent` module:

```
open System

module GradientDescent =

    type Settings = {
        LearningRate: float
        Dataset: List<float * float>
        Iterations: int
    } with
        static member Default dataset = { 
            LearningRate = 0.006
            Dataset = dataset
            Iterations = 5000 
        }

    type ModelResult = {
        Estimate: float -> float
        Cost: Cost
        Thethas: float list
        ThethaCalculationSteps: ThethaCalculationSteps
    }

    and ThethaCalculationSteps = ThethaCalculationSteps of float list list
        with override x.ToString() = match x with ThethaCalculationSteps v -> sprintf "Thethas: %A" v

    and Cost = Cost of float
        with 
            override x.ToString() = match x with Cost v -> sprintf "Cost: %.4f%%" v
            
            static member Compute(data: List<float * float>, thethas: float list) =
                match thethas with
                | thetha0::thetha1::_ ->
                    let sum = 
                        [0..data.Length - 1] 
                        |> List.map (fun i -> data.[i])
                        |> List.map (fun (x, y) -> thetha0 + thetha1 * x - y)
                        |> List.sum

                    Cost <| (1./float data.Length) * (Math.Pow(sum, 2.))
                | _ -> failwith "Could not compute cost function, thethas are not in correct format."

                  

    let nextThetha innerDerivative (settings: Settings) thetha =
        let sum =
            [0..settings.Dataset.Length - 1]
            |> List.map (fun i -> settings.Dataset.[i])
            |> List.map (fun (x, y) -> innerDerivative x y)
            |> List.sum

        thetha - settings.LearningRate * ((1./float settings.Dataset.Length) * sum)

    let estimate settings =
        [0..settings.Iterations]
        |> List.scan (fun thethas _ -> 
            match thethas with
            | thetha0::thetha1::_ ->
                let thetha0 = nextThetha (fun x y -> thetha0 + thetha1 * x - y) settings thetha0
                let thetha1 = nextThetha (fun x y -> (thetha0 + thetha1 * x - y) * x) settings thetha1
                [ thetha0; thetha1 ]
            | _ -> failwith "Could not compute next thethas, thethas are not in correct format.") [0.; 0.]

    let createModel settings =
        let interationSteps = estimate settings

        match List.last interationSteps with
        | thetha0::thetha1::_ as thethas->
            { Estimate = fun  x -> thetha0 + thetha1 * x
              Cost = Cost.Compute(settings.Dataset, thethas)
              Thethas = thethas
              ThethaCalculationSteps = ThethaCalculationSteps interationSteps }
        | _ -> failwith "Failed to create model. Could not compute thethas."
```


## Conclusion


## More to read
