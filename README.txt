Hy,
 this is a very rude implementation for an OO approach to mt4 language.
The library implements:

- A pipe library which is used in various way to keep trak of prices f.e.
- An Expert Advisor Object Oriented approach
- Each Expert Advisor has a listener to understand if the order has been closed by a stop loss (SL) or a take profit (TP)
- Each Expert Advisor can implement and modify at runtime it's SL and TP strategy
- The library can combine using AND, OR or MAJOR strategy all the OO EA strategy added.
- Each EA adds its properties to the interface so any parameter can be configured on the main interface
- Each EA Strategy runs over a window and has a shift to work on.

TODO:
-----

0. Documentation!
1. Implement a multithreading (native?) library to backtest on the current symbol to modify params at runtime (while traind).
2. Refactory of SL and TP MERGE strategy (only simple conservtive AND is currently supported)

There are lots of useful tools, sorry but I need founds to continue work on this.
If you are a passionate developer pls contact me so we can try to extend it with other feature and fixes

Carlo Cancellieri


ccancellieri

ccancellieri@hotmail.com

