for i in $(seq 1 4); do
	grep preproc baseline-$i.log | awk '{ print $6 " " $8 " " $10 " " $12 " " $14 " " $16 " " $18 " " $20 " " $22}' > baseline-$i-queues.log
	grep current baseline-$i.log | awk '{ print $2 " " $4 " " $8 " " $11 " " $14 }' > baseline-$i-fps.log
	paste baseline-$i-fps.log baseline-$i-queues.log > baseline-$i-octave.log
done

for i in $(seq 1 4); do
	grep preproc new-$i.log | awk '{ print $6 " " $8 " " $10 " " $12 " " $14 " " $16 " " $18 " " $20 " " $22}' > new-$i-queues.log
	grep current new-$i.log | awk '{ print $2 " " $4 " " $8 " " $11 " " $14 }' > new-$i-fps.log
	paste new-$i-fps.log new-$i-queues.log > new-$i-octave.log
done
