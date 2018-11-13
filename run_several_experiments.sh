#echo "Current time: $(date +"%T")"
#./run_experiment.sh 0 ro en 42 softmax 0
#echo "Current time: $(date +"%T")"
#./run_experiment.sh 0 ro en 42 sparsemax 0
echo "Current time: $(date +"%T")"
./run_experiment.sh 0 de en 42 csoftmax 0.8 fixed 1.5 
echo "Current time: $(date +"%T")"
./run_experiment.sh 0 de en 42 csparsemax 0.8 actual
echo "Current time: $(date +"%T")"
#./run_experiment.sh 0 ro en 42 softmax 0 none none true 1
#echo "Current time: $(date +"%T")"
#./run_experiment.sh 0 ro en 42 sparsemax 0 none none true 1
#echo "Current time: $(date +"%T")"
