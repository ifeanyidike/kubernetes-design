package checkapi

import "net/http"

func liveness(w http.ResponseWriter, r *http.Request) {
	// This is a simple check to see if the service is running.
	// It does not check the health of any dependencies.
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func leadiness(w http.ResponseWriter, r *http.Request) {
	// This is a simple check to see if the service is ready to handle requests.
	// It does not check the health of any dependencies.
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("READY"))
}
