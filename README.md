# Notes

I chose to sort the arguments because it doesn't make sense to have two entries - one for (alex, sam) and one for (sam, alex). For those two to make sense I would have to understand the meaning of the statement.

It was unclear how to create the constraint between the number of arguments and a statement therefore I opted to not verify the number of arguments for a given statement. For example INPUT love (cat, dog) and INPUT love (cheese) would both be accepted.

---

If all the arguments have a capital letter in it then there is nothing too search with.

Creating filter function where there can be a one or more values that are used to lookup in state.

The filter criteria is values to look up and then different and duplicate values.

First step, if we have values to use to search, search with values given.

Filter down that set one filter at a time in a pipeline.

(X,X,X) -> wants all lists where it contains a value repeated 3 times

(X,Y,4) -> wants all lists where it contains a 4 and its other items don't repeat

(X,Y,4)

after you get lists that contain 4

(1,1,2,2,4)
(X,X,Y,Y,4)

(3,3,4)
(X,X,4)
