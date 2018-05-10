import argparse

##########################################################################################
###                                AUXILIARY FUNCTIONS                                ####
##########################################################################################

def list_of_indeces(path, index):

    """
    Returns a list with a list of indeces that were aligned
    for each sentece and according to its index.
    
    Inputs:
    - path  : path to an .align file
    - index : 0 (source language) / 1 (target language)
    
    Outputs:
    - list_ :
    """

    list_ = list()
    
    assert index in [0,1], "Index has to be 0 or 1"
    assert isinstance(list_, list)
    
    for line in open(path, "r"):
        
        # Skip the headers lines
        if line[0] == "<":
            continue
            
        alignments = line.strip("\n").split(" ")
        
        aux_list = list()
        
        for set_ in alignments:
            set_ = set_.split('-')
            
            if set_[index] not in aux_list:
                aux_list.append(set_[index])
                
        list_.append(aux_list)
    
    return list_


def calculate_score(src_ref_ixs, src_mt_ixs, src_words, stopwords, filter_stopwords):

    """
    Prints the final score of dropped words according to alignments.
    
    Inputs:
    - src_ref_ixs      : list of lists with the index of source words that
                         aligned with reference words
    - src_mt_ixs       : list of lists with the index of source words that
                         aligned with mt predicted words
    - src_words        : list of lists with the source words
    - stopwords        : list with the stop words for the source language
    - filter_stopwords : boolean that indicates whether stopwords are dropped or not
    """

    tot = 0
    nr_src_ref_aligned_words = 0
    
    for (src_ref, src_mt, words) in zip(src_ref_ixs, src_mt_ixs, src_words):
        
        # Create list with the src words ixs that aligned with something
        # of the reference but not with anything from the mt    
        skipped_ixs = set(src_ref) - set(src_mt)

        if filter_stopwords:

            for value in skipped_ixs:
                if words[int(value)] not in stopwords:
                    tot += 1
        
            for value in src_ref:
                if words[int(value)] not in stopwords:
                    nr_src_ref_aligned_words +=1

        else:

            tot += len(skipped_ixs)
            nr_src_ref_aligned_words += len(src_ref)
    
    print("DSW: {:.2f}%".format(100*float(tot)/nr_src_ref_aligned_words)) 


##########################################################################################
###                                AUXILIARY FUNCTIONS                                ####
##########################################################################################

def main():

    parser = argparse.ArgumentParser()

    # Optional arguments
    parser.add_argument("--filter_stopwords", action="store_true",
                        help="If provided, excludes alignments relative to stopwords")
    parser.add_argument("--stopwords_path", type=str,
                        help="Path to the stopwords file")

    # Required arguments
    required = parser.add_argument_group("required arguments")
    required.add_argument("--align_data_path", type=str, required=True,
                          help="Path to the alignment data")
    required.add_argument("--test_source_path", type=str, required=True,
                          help="Path to the source language bpe corpus file")

    args = parser.parse_args()

    if args.filter_stopwords and not args.stopwords_path:
        print("Filtering stopwords requires passing a path to their location")
        exit()

    ALIGNER_DATA_PATH = args.align_data_path
    STOPWORDS_PATH = args.stopwords_path
    SOURCE_PATH = args.test_source_path
    
    # Source words that were aligned with some reference word
    src_ref_ixs_aligned = list_of_indeces(ALIGNER_DATA_PATH + "src_ref.align", 0)

    # Source words that were aligned with some MT predicted word
    src_mt_ixs_aligned = list_of_indeces(ALIGNER_DATA_PATH + "src_mt.align", 0)

    # Create list of source words
    src_words = [line.strip("\n").split(" ") for line in open(SOURCE_PATH, 'r')]

    # Print the final score
    if args.filter_stopwords:
        # Create the list with the desired stopwords
        stopwords = [line.strip("\n") for line in open(STOPWORDS_PATH, 'r')]
        calculate_score(src_ref_ixs_aligned, src_mt_ixs_aligned, src_words, stopwords, 
                                                                args.filter_stopwords) 

    else:
        calculate_score(src_ref_ixs_aligned, src_mt_ixs_aligned, src_words, list(),
                                                                args.filter_stopwords)


if __name__ == "__main__":

    main()
