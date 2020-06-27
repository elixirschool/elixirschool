# OTP concurrency / GenServer homework

Hope you liked the OTP concurrency lesson. Here is your project for it!
Look at the code in file `otp-concurrency.exs`. It should be familiar, it's
the same SimpleQueue implementation as in the lesson. Consider following
modifications:

1. Change the `enqueue` function from an asynchronous to a synchronous one.

The function should preserve it's functionality, but
return the new element instead of `:ok`. The unit tests
could helpful if you get stack

2. Implement a `sum_elements` function that will output a sum of all the numbers inside the queue

The function should:
- assume that every object in the queue is an integer
- return an integer which is a sum of all numbers in the queue
- not modify the state of the queue

To run tests, execute `elixir otp-concurrency.exs`.

If you get stack, you can check out the `otp-concurrency-solution.exs` file!
