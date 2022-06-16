/* MIT License
 *
 * Copyright (c) 2022 David Schall and EASE lab
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

// Package main implements a client for Greeter service.
package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	log "github.com/sirupsen/logrus"

	// pb "google.golang.org/grpc/examples/helloworld/helloworld"
	m5ops "client/m5"

	grpcClients "github.com/ease-lab/vSwarm-proto/grpcclient"
)

const (
	defaultInput = "1"
)

var (
	print_version  = flag.Bool("version", false, "Version of client")
	functionName   = flag.String("function-name", "helloworld", "Specify the name of the function being invoked.")
	url            = flag.String("url", "0.0.0.0", "The url to connect to")
	port           = flag.String("port", "50051", "the port to connect to")
	input          = flag.String("input", defaultInput, "Input to the function")
	functionMethod = flag.String("function-method", "default", "Which method of benchmark to invoke")
	n              = flag.Int("n", 10, "Number of invokations")
	logfile        = flag.String("logging", "", "Log to file instead of standart out")
	m5_enable      = flag.Bool("m5ops", false, "Enable m5 magic instructions")
	// Client
	client    grpcClients.GrpcClient
	generator grpcClients.Generator
	m5        m5ops.M5Ops
)

func main() {
	flag.Parse()

	if *print_version {
		fmt.Println(version)
		os.Exit(0)
	}

	// open file and create if non-existent
	if *logfile != "" {
		file, err := os.OpenFile(*logfile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			log.Fatal(err)
		}
		defer file.Close()
		log.SetOutput(file)
	}

	log.Println("-- Invokation test --")
	// Add also the m5 magic instructions
	if *m5_enable {
		m5 = m5ops.NewM5Ops()
		defer m5.Close()

		m5.Fail(0, 20) // 20: Connection established
	}

	// ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	// defer cancel()
	ctx := context.Background()

	// Set up a connection to the function server.
	serviceName := grpcClients.FindServiceName(*functionName)
	client = grpcClients.FindGrpcClient(serviceName)

	client.Init(ctx, *url, *port)
	defer client.Close()

	log.Printf("Greeting: %s")

	// conn, err := grpc.Dial(*addr, grpc.WithInsecure())
	// if err != nil {
	// 	log.Fatalf("FAIL: did not connect: %v", err)
	// }
	// defer conn.Close()
	// c := pb.NewGreeterClient(conn)

	// // // Contact the server and print out its response.

	generator = client.GetGenerator()
	generator.SetGenerator(grpcClients.Unique)
	generator.SetValue(*input)
	generator.SetMethod(*functionMethod)
	pkt := generator.Next()

	log.Printf("Greeting: %s")
	reply := client.Request(ctx, pkt)
	// log.Debug(reply)

	log.Printf("Greeting: %s", reply)

	if *m5_enable {
		invokeFunctionInstrumented(ctx, *n)
	} else {
		invokeFunction(ctx, *n)
	}

	log.Printf("Finished invoking: %s", reply)
	log.Printf("SUCCESS: Calling functions for %d times", *n)
}

func invokeFunction(ctx context.Context, n int) {
	// Print 5 times the progress
	mod := 1
	if n > 2*5 {
		mod = n / 5
	}
	for i := 0; i < n; i++ {

		pkt := generator.Next()
		client.Request(ctx, pkt)
		if i%mod == 0 {
			log.Printf("Invoked for %d times\n", i)
		}
	}
}

func invokeFunctionInstrumented(ctx context.Context, n int) {
	// Print 5 times the progress
	mod := 1
	if n > 2*5 {
		mod = n / 5
	}
	for i := 0; i < n; i++ {

		pkt := generator.Next()

		m5.Fail(0, 21) // 21: Send Request

		// c.SayHello(ctx, &pb.HelloRequest{Name: *name})
		client.Request(ctx, pkt)

		m5.Fail(0, 22) // 21: Send Request
		if i%mod == 0 {
			log.Printf("Invoked for %d times\n", i)
		}
	}
}

func Dump() {
	// defer func() {
	// 	// recover from panic if one occured. Set err to nil otherwise.
	// 	if recover() != nil {
	// 		err = errors.New("array index out of bounds")
	// 	}
	// }()
	// defer func() {
	// 	if r := recover(); r != nil {
	// 		fmt.Println("Recovered in f", r)
	// 	}
	// }()

	// m5ops.DumpStats(0, 0)
	// m5ops.

}
