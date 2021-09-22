import pandas as pd


def run():
    
    df = pd.read_csv("test_data.csv")
    newDf = df.drop(["A", "D",], axis=1)

    receiverSender = pd.crosstab(index=newDf["B"],
                                columns=newDf["C"],
                                margins=True)

    receiverSender = receiverSender.rename({'All': 'rowTotal'}, axis=1)

    finalDF = receiverSender/receiverSender.loc["All","rowTotal"]
    finalDF.to_csv("output.csv")

    print(finalDF)

if __name__ == "__main__":
    run()