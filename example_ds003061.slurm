#!/bin/bash
#SBATCH --job-name="bidsdl"
#SBATCH --output="/home/arno/eeglab/plugins/bids_dl/log/log_example_ds003061.out"
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32Gb
#SBATCH --export=ALL
#SBATCH -t 24:00:00
#SBATCH --mail-user=adelorme@ucsd.edu
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH -A csd403
source ~/.bashrc
cd /home/arno/eeglab/plugins/bids_dl
module load matlab
matlab -nodisplay -nosplash -nodesktop < /home/arno/eeglab/plugins/bids_dl/example_ds003061.m
