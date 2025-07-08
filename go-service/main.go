package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)



type Order struct {
	OrderID string  `json:"order_id"`
	Amount  float64 `json:"amount"`
	Item    string  `json:"item"`
}

var (
	s3Client *s3.Client
)


type Response struct {
	Message string `json:"message"`
	Method  string `json:"method"`
	Path    string `json:"path"`
}

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("Received request: %s %s", request.HTTPMethod, request.Path)

	response := Response{
		Message: "Hello from Go!",
		Method:  request.HTTPMethod,
		Path:    request.Path,
	}
	// Upload the receipt to S3 using the helper method

	responseBody, err := json.Marshal(response)
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: 500,
			Body: fmt.Sprintf(`{"error": "Failed to marshal response: %s"}`, err.Error()),
			Headers: map[string]string{
				"Content-Type": "application/json",
			}, 
		}, nil
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       string(responseBody),
		Headers: map[string]string{
			"Content-Type":                "application/json",
			"Access-Control-Allow-Origin": "*",
		},
	}, nil
}

func main() {
	lambda.Start(handleRequest)
}