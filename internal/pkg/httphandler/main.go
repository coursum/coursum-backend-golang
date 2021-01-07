package httphandler

import (
	"github.com/coursum/coursum-backend/internal/pkg/elasticclient"
	"github.com/gin-gonic/gin"
	"net/http"
	"strconv"
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
	// Search function, WIP
	// Use like this: http://localhost:8000/search?semester=秋&times=火曜日
	// or this: http://localhost:8000/search?query=情報基礎&teacher=萩野
	// All search parameters can be combined!
	options := elasticclient.SearchOptions{
		Query:     c.Query("query"),
		Category:  c.Query("category"),
		Classroom: c.Query("classroom"),
		Language:  c.Query("language"),
		Semester:  c.Query("semester"),
		Teacher:   c.Query("teacher"),
		Times:     c.Query("times"),
		Giga:      c.Query("giga") == "true",
	}
	if from, err := strconv.Atoi(c.Query("from")); err == nil {
		options.From = from
	}
	if size, err := strconv.Atoi(c.Query("size")); err == nil {
		options.Size = size
	} else {
		// This is an arbitrary number for the maximum page size
		options.Size = 1000
	}
	var courses elasticclient.ClientSearchResult
	var err error
	if options == (elasticclient.SearchOptions{}) {
		courses, err = elasticclient.GetAllCourse(options)
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
