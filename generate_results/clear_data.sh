echo "WARNING: Make sure this script is being called from the original folder"
echo "Are you sure you want to delete all extra data? (y/n)"
echo
read answer

if [ "$answer" = "y" ]
then

    echo "Removing data files ..."
    rm corpus.*
    rm test.*
    echo "Cleaning mt_predictions folder..."
    rm -rf mt_predictions
    mkdir mt_predictions
    echo "Cleaning aligner_data folder..."
    rm -rf aligner_data
    mkdir aligner_data

elif [ "$answer" = "n" ]
then
    echo "Operation cancelled"

else 
    echo "Invalid answer"

fi


