import io.cayla.web { Handler, route, Response, ok }
import ceylon.promise { Deferred, Promise }

shared object mycontroller {
	route("/")
	shared class Index() extends Handler() {
		shared actual Promise<Response> handle() {
			Deferred<Response> response = Deferred<Response>();
			response.fulfill(ok { "hello_promise"; });
			return response.promise;
		}
	}
}