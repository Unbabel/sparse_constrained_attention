import argparse

def create_fertility_dictionary(source, align):
    print('Creating fertility dictionary...')
    fertility_dict = {}
    with open(source) as f_source, open(align) as f_align:
        for sentence, alignment in zip(f_source, f_align):
            words = sentence.rstrip().split()
            aligned_pairs = alignment.rstrip().split()
            fert = [0] * len(words)
            for pair in aligned_pairs:
                idxs = pair.split('-')
                a = int(idxs[0])
                b = int(idxs[1])
                fert[a] += 1
            for a, word in enumerate(words):
                if word not in fertility_dict or fertility_dict[word] < fert[a]:
                    fertility_dict[word] = fert[a]
    return fertility_dict

def generate_actual_fertilities(source, align, output):
    print('Generating %s...' % output)
    with open(source) as f_source, open(align) as f_align, \
         open(output, 'w') as f_out:
        for sentence, alignment in zip(f_source, f_align):
            words = sentence.rstrip().split()
            aligned_pairs = alignment.rstrip().split()
            ferts = [0] * len(words)
            for pair in aligned_pairs:
                idxs = pair.split('-')
                a = int(idxs[0])
                b = int(idxs[1])
                ferts[a] += 1
            # Minimum fertility is 1.
            ferts = [max(fert, 1) for fert in ferts]
            f_out.write(' '.join([str(fert) for fert in ferts]) + '\n')

def generate_guided_fertilities(fertility_dict, source, output):
    print('Generating %s...' % output)
    with open(source) as f_source, open(output, 'w') as f_out:
        for sentence in f_source:
            words = sentence.rstrip().split()
            # Minimum fertility is 1.
            ferts = [fertility_dict[word] if word in fertility_dict else 1
                     for word in words]
            ferts = [max(fert, 1) for fert in ferts]
            f_out.write(' '.join([str(fert) for fert in ferts]) + '\n')

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument('-method', type=str, default='guided')
    parser.add_argument('-train_source', type=str, required=True)
    parser.add_argument('-train_align', type=str, required=True)
    parser.add_argument('-dev_source', type=str, required=True)
    parser.add_argument('-dev_align', type=str, required=True)
    parser.add_argument('-test_source', type=str, required=True)
    parser.add_argument('-test_align', type=str, required=True)

    opt = parser.parse_args()

    if opt.method == 'guided':
        fertility_dict = create_fertility_dictionary(opt.train_source,
                                                     opt.train_align)
        for source in [opt.train_source, opt.dev_source, opt.test_source]:
            generate_guided_fertilities(fertility_dict,
                                        source,
                                        source + '.fert.guided')
    elif opt.method == 'actual':
        for source, align in zip([opt.train_source, opt.dev_source,
                                  opt.test_source],
                                 [opt.train_align, opt.dev_align,
                                  opt.test_align]):
            generate_actual_fertilities(source, align,
                                        source + '.fert.actual')
    else:
        raise NotImplementedError

if __name__ == "__main__":
    main()
