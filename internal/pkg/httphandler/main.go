package httphandler

import (
	"github.com/coursum/coursum-backend/internal/pkg/elasticclient"
	"github.com/gin-gonic/gin"
	"net/http"
)

// pretty will Prettify the JSON response
func pretty(c *gin.Context, data interface{}) {
	_, pretty := c.Request.URL.Query()["pretty"]

	if pretty {
		c.IndentedJSON(http.StatusOK, data)
	} else {
		c.JSON(http.StatusOK, data)
	}
}

// GetIndex will respond the index page
func GetIndex(c *gin.Context) {
	c.HTML(http.StatusOK, "index.tmpl", gin.H{
		"title":   "Hello, Gin",
		"message": "Coursum Server",
	})
}

// GetPing will respond { "message": "ping" }
func GetPing(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "pong",
	})
}

// GetCount will respond the document count
func GetCount(c *gin.Context) {
	counts, err := elasticclient.GetAllDocumentCounts()
	if err != nil {
		c.String(http.StatusBadRequest, err.Error())
		return
	}

	pretty(c, counts)
	return
}

// GetSearch will ...
func GetSearch(c *gin.Context) {
	options := elasticclient.SearchOptions{
		Query:    c.Query("query"),
		Language: c.Query("language"),
		Teacher:  c.Query("teacher"),
		Giga:     c.Query("giga") == "true",
	}
	var courses elasticclient.ClientSearchResult
	var err error
	if options == (elasticclient.SearchOptions{}) {
		courses, err = elasticclient.GetAllCourse()
	} else {
		courses, err = elasticclient.SearchCourse(options)
	}

	if err != nil {
		c.String(http.StatusBadRequest, err.Error())
		return
	}

	pretty(c, courses)

	return
}
