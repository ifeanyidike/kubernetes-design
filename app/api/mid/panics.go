package mid

import (
	"context"
	"fmt"
	"runtime/debug"
)

func Panics(ctx context.Context, handler Handler) (err error) {
	// Defer a function to recover from a panic and set the err return
	// variable after the fact.
	defer func() {
		if rec := recover(); rec != nil {
			trace := debug.Stack()
			err = fmt.Errorf("PANIC [%v] TRACE[%s]", rec, string(trace))
		}
	}()
	return handler(ctx)
}
