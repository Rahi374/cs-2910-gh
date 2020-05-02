cd baseline
./uselib ../../download/MOT20-02.mp4 &> ../baseline-1.log
./uselib ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 &> ../baseline-2.log
./uselib ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 &> ../baseline-3.log
./uselib ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 &> ../baseline-4.log

cd ../darknet
./uselib ../../download/MOT20-02.mp4 &> ../new-1.log
./uselib ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 &> ../new-2.log
./uselib ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 &> ../new-3.log
./uselib ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 ../../download/MOT20-02.mp4 &> ../new-4.log
