# coding: utf-8

import pandas as pd 
import numpy as np
import os

def read_data(n_steps, n_channels, data_path='./data'):
    """ read in datas to feed into lstm
    XXX: 
        1. n_steps must no greater than X data shape(years)
        2. X/Y must have one on one map for each sample, gen_data.sh
    is highly recommended
        3. Y should be sorted
        4. some stock may not be included, due to shape reason #1, or
    fail to have Y

    data format:
        path_x: n_samples files, each file contains n_channels lines,
                n_steps as years
        path_y: one file as n_samples rows, each file contains two
                columns(stock, labels)

    input: 
        n_steps: read in num of years, from oldest
        n_channels: channel number
        data_path: for LSTM, *NOT* database 

    returns:
        X: (n_samples, n_steps, n_channels)
        labels
        n_channels
    """

    # Paths
    path_x = os.path.join(data_path, 'X')
    path_y = os.path.join(data_path, 'Y')

    # Read labels
    label_path = os.path.join(path_y, "labels.csv")
    if(not os.path.exists(label_path)):
        raise OSError("label_path doesn't exist")

    labels = pd.read_csv(label_path, dtype={0: str}, header = None)

    name_y = labels[0].tolist()

    files = os.listdir(path_x)
    files.sort()

    name_x = [f[:6] for f in files]

    if not name_x == name_y:
        raise ValueError("x and y doesn't match")

    # Initiate array
    X = np.zeros((len(name_x), n_steps, n_channels))
    for (i_sample, f) in enumerate(files):
        dat_ = pd.read_csv(os.path.join('data', 'X', f), delimiter=',', delim_whitespace=False, header=None)

        # n_steps + 2: workaround for the trailing comma
        X[i_sample,:,:] = dat_.T.as_matrix()[2:n_steps+2,:]

    # Return 
    return X, labels[1].values

def standardize(train, test):
    """ Standardize data """

    x_mean = np.mean(train, axis=0)

    # Standardize train and test
    X_train = (train - np.mean(train, axis=0)[None,:,:]) / np.std(train, axis=0)[None,:,:]
    X_test = (test - np.mean(test, axis=0)[None,:,:]) / np.std(test, axis=0)[None,:,:]

    return X_train, X_test

def one_hot(labels, n_class = 6):
    """ One-hot encoding """
    expansion = np.eye(n_class)
    y = expansion[:, labels-1].T
    assert y.shape[1] == n_class, "Wrong number of labels!"

    return y

def get_batches(X, y, batch_size = 100):
    """ Return a generator for batches """
    n_batches = len(X) // batch_size
    X, y = X[:n_batches*batch_size], y[:n_batches*batch_size]

    # Loop over batches and yield
    for b in range(0, len(X), batch_size):
        yield X[b:b+batch_size], y[b:b+batch_size]
