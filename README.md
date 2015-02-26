Optimus Prime
=============

![Optimus Prime][1]


ETL - Extract, Transform, Load
------------------------------

This project provides a framework to set up data processing pipelines for
game analytics. Pipelines extract data from various sources (flurry, s3,
databases...), clean and transform it, and load it into any number of
destinations.


### Usage

Create an instance of the `OptimusPrime::Pipeline` class, passing a hash of
processing steps to the constructor. For example:

    #     a   b
    #     |   |
    #     c   d
    #      \ /
    #       e
    #      / \
    #     f   g

    pipeline = OptimusPrime::Pipeline.new({
      a: {
        class: 'Source',
        params: { data: (1..10).to_a },
        next: ['c']
      },
      b: {
        class: 'Source',
        params: { data: (100..110).to_a },
        next: ['d']
      },
      c: {
        class: 'Transform',
        next: ['e']
      },
      d: {
        class: 'Transform',
        next: ['e']
      },
      e: {
        class: 'Transform',
        next: ['f', 'g']
      },
      f: {
        class: 'Destination'
      },
      g: {
        class: 'Destination'
      }
    })

To start the pipeline, call

    pipeline.start

This will start streaming data from the sources, through each intermediate step,
to the destinations. Steps are connected by sized queues, that will block when
full. This enables backpressure, preventing excessive memory usage if
destinations can't process the data as fast as the sources can produce it.

To wait for a pipeline to finish, call

    pipeline.join


### Writing processing steps

Processing steps work in a similar way to [nodejs streams][2]. See the existing
implementations and the tests for examples.

#### Sources

To write a new data source, subclass `OptimusPrime::Source` and implement the
`#each` method. `#each` should yield arbitrary ruby objects. It should never
yield `nil` as that is used to signal the end of the stream, and will be sent
automatically once all data has been consumed.

#### Destinations

To write a new destination or transform step, subclass
`OptimusPrime::Destination` and implement the `#write` method. This method takes
a ruby object as input (it is assumed that you know what kind of object it will
be). It can transform the input, write it to an external data store if needed,
and send it down the pipeline by passing it to the `#send` method. Never pass
`nil` to the `#send` method, as that is used to signal the end of the stream.


[1]: http://upload.wikimedia.org/wikipedia/en/1/19/Optimus10108pieces.jpg
[2]: http://nodejs.org/api/stream.html
