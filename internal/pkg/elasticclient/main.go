package elasticclient

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/joho/godotenv"
	"github.com/olivere/elastic/v7"
)

// HitStat is ...
type HitStat struct {
	Total   int64
	Latency int64 // Unit: milliseconds
}

// Hit is ...
type Hit interface {
}

// ClientSearchResult is ...
type ClientSearchResult struct {
	Query string `json:",omitempty"`
	Stat  HitStat
	Hits  []Hit
}

var esURL string
var esDefaultIndex string

// loadEnv will ...
func loadEnv() {
	err := godotenv.Load()
	if err != nil {
		fmt.Println(err)
		panic("Error loading .env file")
	}

	esURL = os.Getenv("ELASTICSEARCH_URL")
	esDefaultIndex = os.Getenv("ELASTICSEARCH_DEFAULT_INDEX")

	return
}

// initClient will connect to the elasticsearch instance
func initClient() (client *elastic.Client) {
	loadEnv()

	client, err := elastic.NewClient(elastic.SetURL(esURL))
	if err != nil {
		fmt.Println(err)
		panic("fail to connect to elasticsearch instance")
	}

	fmt.Println("connected successfully")
	return
}

var client = initClient()
var ctx = context.Background()

// sourceQueryString will convert an elastic.Query to its JSON source (for debugging)
// func sourceQueryString(query elastic.Query) (queryString interface{}, err error) {
func sourceQueryString(query elastic.Query) (queryString string, err error) {
	src, err := query.Source()
	if err != nil {
		fmt.Println(err)
		return
	}

	data, err := json.MarshalIndent(src, "", "  ")
	if err != nil {
		panic(err)
	}

	queryString = string(data)

	return
}

// GetAllDocumentCounts will return the document count of all indices
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

// GetAllCourse will ...
func GetAllCourse() (clientSearchResult ClientSearchResult, err error) {
	query := elastic.NewMatchAllQuery()

	searchResult, err := client.
		Search(esDefaultIndex).
		Query(query).
		From(0).Size(10).
		Do(ctx)
	if err != nil {
		fmt.Println(err)
		return
	}

	clientSearchResult.Stat.Latency = searchResult.TookInMillis
	clientSearchResult.Stat.Total = searchResult.TotalHits()

	for _, hit := range searchResult.Hits.Hits {
		clientSearchResult.Hits = append(clientSearchResult.Hits, hit.Source)
	}

	return
}
