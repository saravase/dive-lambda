package main

import (
	"context"
	"encoding/json"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type (
	Request struct {
		Event string      `json:"event"`
		Body  RequestBody `json:"body"`
	}
	RequestBody struct {
		Name string `json:"name"`
	}
)

// handler handle batch SQS Messages and return report failures if any
func handler(ctx context.Context, sqsEvent events.SQSEvent) (events.SQSEventResponse, error) {
	batchItemFailures := []events.SQSBatchItemFailure{}

	// handle batch SQS message
	for idx := range sqsEvent.Records {
		message := &sqsEvent.Records[idx]
		body := []byte(message.Body)
		req := Request{}

		if err := json.Unmarshal(body, &req); err != nil {
			log.Printf("lambda parse request message %s failed %v", message.MessageId, err)
			batchItemFailures = append(batchItemFailures, events.SQSBatchItemFailure{
				ItemIdentifier: message.MessageId,
			})
			continue
		}

		log.Printf("message id: %v, event: %s, name : %s\n", message.MessageId, req.Event, req.Body.Name)
	}

	return events.SQSEventResponse{
		BatchItemFailures: batchItemFailures,
	}, nil
}

func main() {
	lambda.Start(handler)
}
