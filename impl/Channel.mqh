//+------------------------------------------------------------------+
//|                                                      Channel.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

/*
typedef 
template <typename T> 
int (* FCondition)(T &p[], int idx1, int idx2);
*/

template <typename T>
class Pipe {
private:

            T pipe[];
            
            int MaxIdx;
            int MinIdx;
            
            
                  bool checkFromTo(int from, int to){
                        if (from>=to){
                           Print(__FUNCTION__,"ERROR: From >= To");
                           return false;
                        } else if (to>ArraySize(pipe)){
                           Print(__FUNCTION__,"ERROR: 'To' is out of range");
                           return false;
                        }
                        return true;
                     }
                     
                     
                  void pushMax(int &idxMax[]){
       /*              
    Print("Looking at pipe: =========");
      for(int i=0; i<ArraySize(pipe); i++)
      {
Print("("+i+"):  "+pipe[i], " time: ",Time[i+1]);
     }
     */
                     
                     int to = ArraySize(pipe)-1;
                     int from = 1;
                     for (int idx=from; idx<to; idx++){
                        T valLeft=pipe[idx-1];
                        T val=pipe[idx];
                        T valRight=pipe[idx+1];
                        int size = ArraySize(idxMax);
                        if (size > 0 && pipe[idx]==pipe[idxMax[size-1]])
                           continue;
                        else if (valLeft < val && val > valRight){
         //                  Print(__FUNCTION__, " MAX found====: ",val," size: ",size+1, " idx: ",idx);
                           ArrayResize(idxMax,size+1);
                           idxMax[size]=idx;
                        }
                     }
                  }
                     
                  
                  int searchForMax(){
                  
                     int to = ArraySize(pipe)-1;
                     int from = 1;
                     int ret=-1;
                     for (int idx=from; idx<to; idx++){
                        T valLeft=pipe[idx-1];
                        T val=pipe[idx];
                        T valRight=pipe[idx+1];
                        if (valLeft < val && val > valRight){
                           if (ret==-1)
                              ret=idx;
                           else if (pipe[idx]>pipe[ret]){
                              ret=idx;
                           }
                        }
                     }
                     return ret;
                  }
                  
                  
                  void pushMin(int &idxMin[]){
                     int to = ArraySize(pipe)-1;
                     int from = 1;
                     for (int idx=from; idx<to; idx++){
                        T valLeft=pipe[idx-1];
                        T val=pipe[idx];
                        T valRight=pipe[idx+1];
                        int size = ArraySize(idxMin);
                        if (size > 0 && pipe[idx]==pipe[idxMin[size-1]])
                           continue;
                        else if (valLeft > val && val < valRight){
                           ArrayResize(idxMin,size+1);
                           idxMin[size]=idx;
                        }
                     }
                  }
                  
                  int searchForMin(){
                     int to = ArraySize(pipe)-1;
                     int from = 1;
                     int ret=-1;
                     for (int idx=from; idx<to; idx++){
                        T valLeft=pipe[idx-1];
                        T val=pipe[idx];
                        T valRight=pipe[idx+1];
                        if (valLeft > val && val < valRight){
                           if (ret==-1)
                              ret=idx;
                           else if (pipe[idx]<pipe[ret]){
                              ret=idx;
                           }
                        }
                     }
                     return ret;
                  }
                  
                  
                  static int push( T &theArray[],  T  value) {
                     
                     int size = ArraySize( theArray );
                     
                     if (ArrayCopy(theArray, theArray, 1, 0, size-1) == size-1){
                        theArray[0] = value;
                        return size;
                     }
                     return -1;
                  }
                  
                  
public:
                  Pipe(int size, T initialValue){
                     ArrayResize(pipe,size);
                     ArrayInitialize(pipe,initialValue);
                  }
                  
                   Pipe(Pipe &p){
                     ArrayCopy(this.pipe,p.pipe,0,0);
                  }
                  
                  T getValue(int idx){
                     if (idx<ArraySize(pipe) && idx>-1)
                        return pipe[idx];
                        
                     return NULL;
                  }
                  
                  int push(T value){
                     int pos = push(pipe,value);
                     if (pos>-1){
                        MaxIdx=-1;
                        MinIdx=-1;
                        return pos;
                     }
                     Print(__FUNCTION__,"ERROR: Unable to push value: ",value);
                     return -1;
                  }
                  
                  void calcMax(int &idxMax[]){
                     int size = ArraySize(pipe);
                     int from = 1;
                     int to = size-1;
                     pushMax(idxMax);
                  }

                  void calcMin(int &idxMin[]){
                     int size = ArraySize(pipe);
                     int from = 1;
                     int to = size-1;
                     pushMin(idxMin);
                  }
                  
                  T avg(int from, int to){
                     if (!checkFromTo(from,to)) {
                        return NULL;
                     }
                     T ret=0;
                     for (int i=from; i<to; i++)
                        ret=ret+pipe[i];
                     
                     return ret/(to-from);
                  }
                  
                  T avg(int from=0){
                     return avg(from,ArraySize(pipe));
                  }
                  
                  
                  int maxIdx(){
                     //return ArrayMaximum(pipe);
                     // TODO
                     int idxMax[];
                     calcMax(idxMax);
                     int size = ArraySize(idxMax);
                     int idx=-1;
                     if (size>0)
                        idx=idxMax[0];
                     for (int i=1; i<size; i++){
                        if (pipe[idxMax[i]]>pipe[idx]){
                           idx=idxMax[i];
                        }
                     }
                     return idx;
                  }
                  
                  int minIdx(){
                     //return ArrayMinimum(pipe);
                     // TODO
                     int idxMin[];
                     calcMin(idxMin);
                     int size = ArraySize(idxMin);
                     int idx=-1;
                     if (size>0)
                        idx=idxMin[0];
                     for (int i=1; i<size; i++){
                        if (pipe[idxMin[i]]<pipe[idx]){
                           idx=idxMin[i];
                        }
                     }
                     return idx;
                  }
                  
                  int getSize(){
                     return ArraySize(pipe);
                  }
                  
                 ~Pipe(){
                     ArrayFree(pipe);
                 }
                 
                  
                  
                  int nextMinIdx(int idx){
                     int idxMin[];
                     calcMin(idxMin);
       /*              
    Print("MIN =========");
      for(int i=0; i<ArraySize(idxMin); i++)
      {
Print("("+i+"):  "+pipe[idxMin[i]]);
     }
     */
                     //Print(__FUNCTION__, " min size: ",ArraySize(idxMin)," max size: ",ArraySize(idxMax));
                     if (idx>-1 && ArraySize(idxMin)>idx)
                        return idxMin[idx];
                     return -1;
                  }
                  
                  
                  
                  int nextMaxIdx(int idx){
                     int idxMax[];
                     calcMax(idxMax);
/*                     
      Print("MAX =========");
         for(int i=0; i<ArraySize(idxMax); i++)
         {
         Print("("+i+"):  "+pipe[idxMax[i]]);
        }
        */
                     if (idx>-1 && ArraySize(idxMax)>idx)
                        return idxMax[idx];
                     return -1;
                  }
                  
                  
     };



class Channel {
private:          
            Pipe<double> *channel;
            Pipe<datetime> *time;
            
            /*
            template<typename T>
            static int whileMax(Pipe<T> &p, int idx1, int idx2){
               return p.getValue(idx1)>p.getValue(idx2);
            }
            
            template<typename T> 
            static int whileMin(Pipe<T> &p, int idx1, int idx2){
               return p.getValue(idx1)<p.getValue(idx2);
            }
            */
            
   public:
             
             Channel(int size=50, double initialValue=0) {
                  
                     channel = new Pipe<double>(size,initialValue);
                     time = new Pipe<datetime>(size,Time[0]);
               };
               
               ~Channel(){
                  delete(channel);
                  delete(time);
               };
               
               template<typename T> 
               Pipe<T> getChannel(){
                  return channel;//GetPointer
               }
               
               
                  double nextMin(int from){//, int to){
                     int idx=channel.nextMinIdx(from);//,to);
                     return channel.getValue(idx);
                  }
                  
                  int nextMinIdx(int from){//, int to){
                     return channel.nextMinIdx(from);//,to);
                  }
               
                  double nextMax(int from){//, int to){
                     int idx=channel.nextMaxIdx(from);//,to);
                     return channel.getValue(idx);
                  }
                  
                  int nextMaxIdx(int from){//, int to){
                     return channel.nextMaxIdx(from);//,to);
                  }
               
                  double avg(int from=0){
                     return channel.avg(from);
                  }
               
                  double max(){
                     int idx = channel.maxIdx();
                     if (idx>-1)
                        return channel.getValue(idx);
                     else
                        return DBL_MAX;
                  }
                  
                  void calcMax(int &idx[]){
                     channel.calcMax(idx);
                  }
                  
                  void calcMin(int &idx[]){
                     channel.calcMin(idx);
                  }
                  
                  double min(){
                     int idx = channel.minIdx();
                     if (idx>-1)
                        return channel.getValue(idx);
                     else
                        return DBL_MIN;
                  }
               
               int maxIdx(){
                  return channel.maxIdx();
               }
               
               int minIdx(){
                  return channel.minIdx();
               }
               
               int getSize(){
                  return channel.getSize();
               }
               
               double getValue(int idx){
                  return channel.getValue(idx);
               }
               
               datetime getTime(int idx){
                  return time.getValue(idx);
               }
               
                  
                  int push(double value, datetime _time){
                     int pos = channel.push(value);
                     if (pos<0)
                        return pos;
                     if (_time!=NULL)
                        pos=time.push(_time);
                     return pos;
                     
                  }
                  
};