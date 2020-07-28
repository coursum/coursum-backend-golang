package httphandler

import (
	"net/http"

	"github.com/coursum/coursum-backend/internal/pkg/elasticclient"
	"github.com/gin-gonic/gin"
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
	query := c.Query("query")
	var courses elasticclient.ClientSearchResult
	var err error
	if query == "" {
		courses, err = elasticclient.GetAllCourse()
	} else {
		courses, err = elasticclient.SearchCourse(query)
	}

	if err != nil {
		c.String(http.StatusBadRequest, err.Error())
		return
	}

	pretty(c, courses)

	return
}
