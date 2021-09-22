import tensorflow as tf

def run():
    def map_rows(x):
        print(x)
        return x

    filename = tf.constant("test_data.csv")
    dataset  = tf.data.experimental.CsvDataset(filename, record_defaults=[tf.string,tf.string,tf.string,tf.float32], header=True)
    dataset  = dataset.map(map_rows)

    #dataset = tf.data.experimental.make_csv_dataset(filename, batch_size=2)

    key_func    = lambda x: x["B"] + "#" + x["C"]
    reduce_func = lambda key, ds: ds.reduce(lambda s,x: s + 1) 

    ds_aggr = dataset.group_by_window(
                key_func=key_func,
                reduce_func=reduce_func,
                window_size=4
                )

    for element in dataset.as_numpy_iterator():
        print(element)

if __name__ == "__main__":
    run()
