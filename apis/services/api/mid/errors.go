package mid

import (
	"context"
	"net/http"

	"github.com/ardanlabs/service/foundation/logger"
	"github.com/ardanlabs/service/foundation/web"
)

func Errors(log *logger.Logger) web.MidHandler {
	m := func(handler web.Handler) web.Handler {
		h := func(ctx context.Context, w http.ResponseWriter, r *http.Request) error {
			return nil
		}
		return h

	}
	return m
}
