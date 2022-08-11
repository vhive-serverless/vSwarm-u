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
	"time"

	log "github.com/sirupsen/logrus"

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
	functionMethod = flag.String("function-method", "0", "Which method of benchmark to invoke")
	numInvoke      = flag.Int("n", 10, "Number of invocations")
	numWarm        = flag.Int("w", 0, "Number of invocations for warming")
	delay          = flag.Int("delay", 0, "Add a delay between sending requests (us)")
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

	log.Printf("Connection established.\n")

	generator = client.GetGenerator()
	generator.SetGenerator(grpcClients.Unique)
	generator.SetValue(*input)
	generator.SetMethod(*functionMethod)
	pkt := generator.Next()

	reply := client.Request(ctx, pkt)

	log.Printf("Greeting: %s", reply)

	if *numWarm > 0 {
		warmFunction(ctx)
	}

	if *m5_enable {
		invokeFunctionInstrumented(ctx, *numInvoke)
	} else {
		invokeFunction(ctx, *numInvoke)
	}

	log.Printf("Finished invoking: %s", reply)
	log.Printf("SUCCESS: Calling functions for %d times", *numInvoke)
}

func warmFunction(ctx context.Context) {
	log.Printf("Invoke functions %d times for warming", *numWarm)
	if *m5_enable {
		m5.Fail(0, 31) // 31: Start Warming
	}

	invokeFunction(ctx, *numWarm)

	if *m5_enable {
		m5.Fail(0, 32) // 32: End Warming
	}
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
		if *delay > 0 {
			time.Sleep(time.Duration(*delay) * time.Microsecond)
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

		m5.WorkBegin(100+i, 0) // 21: Send Request

		client.Request(ctx, pkt)

		m5.WorkEnd(100+i, 0) // 21: Response received
		if i%mod == 0 {
			log.Printf("Invoked for %d times\n", i)
		}

		if *delay > 0 {
			time.Sleep(time.Duration(*delay) * time.Microsecond)
		}
	}
}
