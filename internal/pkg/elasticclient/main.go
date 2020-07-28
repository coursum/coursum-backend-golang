package elasticclient

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/joho/godotenv"
	"github.com/olivere/elastic/v7"
)

func initClient() (client *elastic.Client, err error) {
	err = godotenv.Load()
	if err != nil {
		panic("Error loading .env file")
	}

	esURL := os.Getenv("ELASTICSEARCH_URL")

	client, err = elastic.NewClient(elastic.SetURL(esURL))
	if err != nil {
		fmt.Println(err)
		panic("connect elasticsearch error")
	}

	fmt.Println("connected successfully")
	return
}

var client, err = initClient()
var ctx = context.Background()

// GetAllDocumentCounts will return
func GetAllDocumentCounts() (counts map[string]int64, err error) {
	indexNames, err := client.IndexNames()
	if err != nil {
		fmt.Println(err)
		return
	}

	counts = make(map[string]int64)
	for _, indexName := range indexNames {
		// Skip system index
		if strings.HasPrefix(indexName, ".") {
			continue
		}

		count, err := client.Count(indexName).Do(ctx)
		if err != nil {
			fmt.Println(err)
			continue
		}

		counts[indexName] = count
	}

	return
}
