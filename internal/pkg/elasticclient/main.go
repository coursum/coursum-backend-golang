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

type SearchOptions struct {
	Query     string
	Classroom string
	Category  string
	Language  string
	Semester  string
	Teacher   string
	Times     string
	Giga      bool
}

// HitStat is ...
type HitStat struct {
	Total   int
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

	esURL = "http://" + os.Getenv("ELASTICSEARCH_USERINFO") + "@elasticsearch:9200"
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

func countDocument(index string) (count int64, err error) {
	count, err = client.Count(index).Do(ctx)
	if err != nil {
		fmt.Println(err)
		return
	}

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
	count, err := countDocument(esDefaultIndex)
	if err != nil {
		fmt.Println(err)
		return
	}

	if count > 1000 {
		count = 1000
	}

	query := elastic.NewMatchAllQuery()

	searchResult, err := client.
		Search(esDefaultIndex).
		Query(query).
		From(0).Size(int(count)).
		Do(ctx)
	if err != nil {
		fmt.Println(err)
		return
	}

	for _, hit := range searchResult.Hits.Hits {
		clientSearchResult.Hits = append(clientSearchResult.Hits, hit.Source)
	}

	clientSearchResult.Stat.Latency = searchResult.TookInMillis
	clientSearchResult.Stat.Total = len(clientSearchResult.Hits)

	return
}

// SearchCourse will ...
func SearchCourse(options SearchOptions) (clientSearchResult ClientSearchResult, err error) {
	count, err := countDocument(esDefaultIndex)
	if err != nil {
		fmt.Println(err)
		return
	}

	searchResult, err := client.
		Search(esDefaultIndex).
		Query(BuildQuery(options)).
		From(0).Size(int(count)).
		Do(ctx)
	if err != nil {
		fmt.Println(err)
		return
	}

	for _, hit := range searchResult.Hits.Hits {
		clientSearchResult.Hits = append(clientSearchResult.Hits, hit.Source)
	}

	clientSearchResult.Stat.Latency = searchResult.TookInMillis
	clientSearchResult.Stat.Total = len(clientSearchResult.Hits)
	clientSearchResult.Query = options.Query

	return
}
