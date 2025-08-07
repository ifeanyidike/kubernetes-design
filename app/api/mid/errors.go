package mid

import (
	"context"

	"github.com/ardanlabs/service/app/api/errs"
	"github.com/ardanlabs/service/foundation/logger"
)

func Errors(ctx context.Context, log *logger.Logger, handler Handler) error {
	err := handler(ctx)

	if err == nil {
		return nil
	}

	log.Error(ctx, "message", "ERROR", err.Error())

	if errs.IsError(err) {
		return errs.GetError(err)
	}

	return errs.Newf(errs.Unknown, "unknown error:%s", err.Error())
}
