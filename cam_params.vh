//localparam [2:0] INDEX[0:7] = '{ 0, 1, 2, 3, 4, 5, 6, 7 };
// parameter changes to support configurable index entries upto 64
localparam int MAX_WORDS = 64;
// Always use 6 bits for index, as 2^6=64
localparam [5:0] INDEX [0:MAX_WORDS-1] = '{
    0, 1, 2, 3, 4, 5, 6, 7,
    8, 9,10,11,12,13,14,15,
   16,17,18,19,20,21,22,23,
   24,25,26,27,28,29,30,31,
   32,33,34,35,36,37,38,39,
   40,41,42,43,44,45,46,47,
   48,49,50,51,52,53,54,55,
   56,57,58,59,60,61,62,63
};

