package m5ops

/*
#cgo CFLAGS: -g
#cgo amd64 LDFLAGS: -L. -lm5ops
#cgo arm64 LDFLAGS: -L. -lm5ops
#include "m5ops.h"
#include "m5_mmap.h"
*/
import "C"
import (
	"os/user"

	log "github.com/sirupsen/logrus"
)

type M5Ops struct {
	// init bool
	mapped bool
}

func NewM5Ops() M5Ops {
	op := M5Ops{}
	op.init()
	return op
}

func isRoot() bool {
	currentUser, err := user.Current()
	if err != nil {
		log.Warn("Cannot get current user")
	}
	return currentUser.Uid == "0"
}

func (op *M5Ops) init() {
	if !isRoot() {
		log.Warn("M5 magic instructions require root access")
		log.Warn("Will not be enabled!!!")
		return
	}
	log.Printf("Initialize M5 magic instructions. M5Ops Addr:%#x\n", C.m5op_addr)
	C.map_m5_mem()
	op.mapped = true
}

func (op *M5Ops) Close() {
	if op.mapped {
		C.unmap_m5_mem()
		op.mapped = false
	}
}

func (op M5Ops) Exit(delay int) {
	if !op.mapped {
		log.Warn("M5 disabled")
		return
	}
	C.m5_exit_addr(C.ulong(delay))
}

func (op M5Ops) Fail(delay, code int) {
	if !op.mapped {
		log.Warn("M5 disabled")
		return
	}
	C.m5_fail_addr(C.ulong(delay), C.ulong(code))
}

func (op M5Ops) DumpStats(delay, period int) {
	if !op.mapped {
		return
	}
	C.m5_dump_stats_addr(C.ulong(delay), C.ulong(period))
}

func (op M5Ops) ResetStats(delay, period int) {
	if !op.mapped {
		return
	}
	C.m5_reset_stats_addr(C.ulong(delay), C.ulong(period))
}

func (op M5Ops) DumpResetStats(delay, period int) {
	if !op.mapped {
		return
	}
	C.m5_dump_reset_stats_addr(C.ulong(delay), C.ulong(period))
}
func (op M5Ops) WorkBegin(workid, threadid int) {
	if !op.mapped {
		return
	}
	C.m5_work_begin_addr(C.ulong(workid), C.ulong(threadid))
}

func (op M5Ops) WorkEnd(workid, threadid int) {
	if !op.mapped {
		return
	}
	C.m5_work_end_addr(C.ulong(workid), C.ulong(threadid))
}

func (op M5Ops) Workload() {
	if !op.mapped {
		return
	}
	C.m5_workload_addr()
}
