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

	grpcClients "github.com/vhive-serverless/vSwarm-proto/grpcclient"
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
	gentype        = flag.String("genType", "unique", "Type of input to generate [unique,random,linear]")
	lowerBound     = flag.Int("lowerBound", 1, "Lower bound while generating input")
	upperBound     = flag.Int("upperBound", 100, "Upper bound while generating input")
	functionMethod = flag.String("function-method", "0", "Which method of benchmark to invoke")
	numInvoke      = flag.Int("n", 10, "Number of invocations")
	numWarm        = flag.Int("w", 0, "Number of invocations for warming")
	delay          = flag.Int("delay", 0, "Add a delay between sending requests (us)")
	logfile        = flag.String("logging", "", "Log to file instead of standart out")
	m5_enable      = flag.Bool("m5ops", false, "Enable m5 magic instructions")
	verbose        = flag.Bool("v", false, "Verbose output")
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
	if *verbose {
		log.SetLevel(log.DebugLevel)
	}

	log.Println("-- Invokation test --")
	// Add also the m5 magic instructions
	if *m5_enable {
		m5 = m5ops.NewM5Ops()
		defer m5.Close()

		m5.Fail(0, 20) // 20: Connection established
	}

	ctx := context.Background()

	// Set up a connection to the function server.
	serviceName := grpcClients.FindServiceName(*functionName)
	client = grpcClients.FindGrpcClient(serviceName)

	if err := client.Init(ctx, *url, *port); err != nil {
		log.Fatalf("Fail to init client: %s\n", err)
	}
	defer client.Close()

	log.Printf("Connection established.\n")

	generator = client.GetGenerator()
	generator.SetGenerator(grpcClients.StringToGeneratorType(*gentype))
	generator.SetValue(*input)
	generator.SetLowerBound(*lowerBound)
	generator.SetUpperBound(*upperBound)
	generator.SetMethod(*functionMethod)
	pkt := generator.Next()

	reply, err := client.Request(ctx, pkt)
	if err != nil {
		log.Errorf("Fail to send request: %s\n", err)
	}

	log.Printf("Greeting: %s", reply)

	if *numWarm > 0 {
		warmFunction(ctx)
	}

	invokeFunction(ctx, *numInvoke, *m5_enable)

	log.Printf("Finished invoking: %s", reply)
	log.Printf("SUCCESS: Calling functions for %d times", *numInvoke)
}

func warmFunction(ctx context.Context) {
	log.Printf("Invoke functions %d times for warming", *numWarm)
	if *m5_enable {
		m5.Fail(0, 31) // 31: Start Warming
	}

	invokeFunction(ctx, *numWarm, false)

	if *m5_enable {
		m5.Fail(0, 32) // 32: End Warming
	}
}

func invokeFunction(ctx context.Context, n int, instrument bool) {
	// Print 5 times the progress
	mod := 1
	if n > 2*5 {
		mod = n / 5
	}
	for i := 0; i < n; i++ {

		pkt := generator.Next()

		if instrument {
			m5.WorkBegin(100+i, 0) // 21: Send Request
		}

		rep, err := client.Request(ctx, pkt)

		if instrument {
			m5.WorkEnd(100+i, 0) // 21: Response received
		}

		if err != nil {
			log.Warnf("Fail to invoke: %s\n", err)
		}
		log.Debugf("Invocation %d: %s", i, rep)
		if i%mod == 0 {
			log.Printf("Invoked for %d times\n", i)
		}
		if *delay > 0 {
			time.Sleep(time.Duration(*delay) * time.Microsecond)
		}
	}
}
