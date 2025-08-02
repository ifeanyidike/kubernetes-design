package web

import (
	"context"
	"net/http"
	"os"
)

type Handler func(ctx context.Context, w http.ResponseWriter, r *http.Request) error

type App struct {
	*http.ServeMux
	shutdown chan os.Signal
}

func NewApp(shutdown chan os.Signal) *App {
	return &App{
		ServeMux: http.NewServeMux(),
		shutdown: shutdown,
	}
}

func (a *App) HandleFunc(pattern string, handler Handler) {
	h := func(w http.ResponseWriter, r *http.Request) {
		handler(r.Context(), w, r)
	}
	a.ServeMux.HandleFunc(pattern, h)
}
