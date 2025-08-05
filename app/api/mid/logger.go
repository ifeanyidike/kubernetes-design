package mid

import (
	"context"
	"fmt"
	"time"

	"github.com/ardanlabs/service/foundation/logger"
	"github.com/ardanlabs/service/foundation/web"
)

type Handler func(ctx context.Context) error

func Logger(ctx context.Context, log *logger.Logger, path, rawQuery, method, remoteAddr string, handler Handler) error {
	v := web.GetValues(ctx)
	if rawQuery != "" {
		path = fmt.Sprintf("%s?%s", path, rawQuery)
	}

	log.Info(ctx, "request started", "method", method, "path", path, "remoteaddr", remoteAddr)
	err := handler(ctx)

	log.Info(ctx, "request completed", "method", method, "path", path, "remoteaddr", remoteAddr,
		"statuscode", v.StatusCode, "since", time.Since(v.Now).String())

	return err
}
