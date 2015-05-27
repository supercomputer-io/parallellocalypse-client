#include <stdio.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <math.h>
#include <e-hal.h>
#include <node.h>
#include <string.h>
#include <v8.h>

#if TEST
#ifndef DEBUG
#define DEBUG 1
#endif
#define TEMP_DIR         "/tmp/thermald/"
#else
#define TEMP_DIR         "/sys/bus/iio/devices/iio:device0/"
#endif

#define TEMP_RAW_PATH    (TEMP_DIR "in_temp0_raw")
#define TEMP_OFFSET_PATH (TEMP_DIR "in_temp0_offset")
#define TEMP_SCALE_PATH  (TEMP_DIR "in_temp0_scale")

/* In Celsius */
#define DEFAULT_MIN_TEMP 0
#define DEFAULT_MAX_TEMP 70

/* Allowed range for user specified THERMALD_{MIN,MAX}_TEMP environment
 * variables */
#define ENV_ALLOWED_MIN_TEMP DEFAULT_MIN_TEMP
#define ENV_ALLOWED_MAX_TEMP 85


/* Both in seconds */
#define MAINLOOP_ITERATION_INTERVAL 1
#define MAINLOOP_WARN_INTERVAL 30

using namespace v8;

struct watchdog {
	int min_temp;  /* Min allowed temperature (in Celcius) */
	int max_temp;  /* Max allowed temperature (in Celcius) */
	int curr_temp; /* Current temperature     (in Celcius) */
};
#define DECLARE_WATCHDOG(Name) struct watchdog (Name) = \
	{ DEFAULT_MIN_TEMP, DEFAULT_MAX_TEMP, (DEFAULT_MAX_TEMP+1) }


int reboot()
{
#if DEBUG
	printf("reboot(): Was called\n");
#endif
	fprintf(stderr, "Zynq temperature over threshold. Rebooting board in 10 secs\n");
	sync();
	fflush(stdout);
	fflush(stderr);

	sleep(10);

	system("/sbin/reboot");

	return E_OK;

#if 0
	return ee_disable_system();
#endif
}

int update_temp_sensor(struct watchdog *wd)
{
	FILE *fp;
	int rc, raw, offset;
	float scale;

	/* Get raw temperature */
	fp = fopen(TEMP_RAW_PATH, "r");
	if (fp == NULL)
		return errno;

	rc = fscanf(fp, "%d", &raw);
	if (rc != 1)
		return ENODATA;

	fclose(fp);

	/* Get offset */
	fp = fopen(TEMP_OFFSET_PATH, "r");
	if (fp == NULL)
		return errno;

	rc = fscanf(fp, "%d", &offset);
	if (rc != 1)
		return ENODATA;

	fclose(fp);

	/* Get scale */
	fp = fopen(TEMP_SCALE_PATH, "r");
	if (fp == NULL)
		return errno;

	rc = fscanf(fp, "%f", &scale);
	if (rc != 1)
		return ENODATA;

	fclose(fp);

	/* Calculate temperature */
	wd->curr_temp = (int)
		roundf((scale / 1000.0) * (((float) raw) + ((float) offset)));


	return 0;
}

void print_warning(struct watchdog *wd, char *limit)
{
	fprintf(stderr, "Rebooting system. Temperature [%d C] is %s"
			" allowed range [[%d -- %d] C].\n",
			wd->curr_temp, limit, wd->min_temp,
			wd->max_temp);
}

int mainloop(struct watchdog *wd)
{
	int rc, last_warning;
	bool should_warn;

	last_warning = -1;
	bool exit_signaled = false;

	while (!exit_signaled) {
		rc = update_temp_sensor(wd);
		if (rc) {
			/* Try one more time before giving up */
			sleep(1);
			rc = update_temp_sensor(wd);
			if (rc) {
				perror("ERROR: Failed to update temperature"
						" sensor value\n");
				return rc;
			}
		}

		/* Limit log spamming */
		should_warn = (last_warning < 0 ||
				last_warning >= MAINLOOP_WARN_INTERVAL) ?
			true : false;

		if (wd->min_temp > wd->curr_temp) {
			if (should_warn) {
				print_warning(wd, "below");
				last_warning = 0;
			} else {
				last_warning += MAINLOOP_ITERATION_INTERVAL;
			}
			exit_signaled = true;
		} else if (wd->curr_temp > wd->max_temp) {
			if (should_warn) {
				print_warning(wd, "above");
				last_warning = 0;
			} else {
				last_warning += MAINLOOP_ITERATION_INTERVAL;
			}
			exit_signaled = true
		} else {
			last_warning = -1;
		}
		if(!exit_signaled)
			sleep(MAINLOOP_ITERATION_INTERVAL);
	}

	return 0;
}

void get_limits_from_env(struct watchdog *wd)
{
	int rc, tmp, env_min, env_max;
	char *str;

	env_min = wd->min_temp;
	env_max = wd->max_temp;

	str = getenv("THERMALD_MAX_TEMP");
	if (str) {
		rc = sscanf(str, "%d", &tmp);
		if (rc == 1) {
			env_max = tmp;
		} else {
			fprintf(stderr, "Ignoring malformed"
				       " THERMALD_MAX_TEMP\n");
		}
	}
	str = getenv("THERMALD_MIN_TEMP");
	if (str) {
		rc = sscanf(str, "%d", &tmp);
		if (rc == 1) {
			env_min = tmp;
		} else {
			fprintf(stderr, "Ignoring malformed"
				       " THERMALD_MIN_TEMP\n");
		}
	}

	/* Range check for insane values */
	if (env_max <= env_min) {
		fprintf(stderr, "Ignoring insane THERMALD_{MIN,MAX}_TEMP"
				" environment values.\n");
		return;
	}

	if (env_max <= ENV_ALLOWED_MAX_TEMP &&
		ENV_ALLOWED_MIN_TEMP < env_max)
		wd->max_temp = env_max;
	else {
		fprintf(stderr, "Ignoring THERMALD_MAX_TEMP value.\n");
	}

	if (ENV_ALLOWED_MIN_TEMP <= env_min &&
			env_min < wd->max_temp)
		wd->min_temp = env_min;
	else {
		fprintf(stderr, "Ignoring THERMALD_MIN_TEMP value.\n");
	}

}


/* Hack: Doing a e_init() / e_reset_system() / e_finalize() salute will shut
 * down the north, south, and west eLinks. */
static int disable_nsw_elinks()
{
	int rc = E_OK;

	rc = e_init(NULL);
	if (rc != E_OK) {
		fprintf(stderr, "ERROR: Failed to initialize Epiphany "
				"platform.\n");
		return rc;
	}

	rc = e_reset_system();
	if (rc != E_OK) {
		fprintf(stderr, "ERROR: e_reset_system() failed.\n");
	}

	e_finalize();

	return rc;
}

int start()
{
	int rc;
	DECLARE_WATCHDOG(wd);

	fprintf(stderr, "Parallella thermal watchdog daemon starting...\n");

	get_limits_from_env(&wd);

	fprintf(stderr, "Allowed temperature range [%d -- %d] C.\n",
			wd.min_temp, wd.max_temp);


	/* First, ensure chip is in lowest possible power state */
	rc = disable_nsw_elinks();
	if (rc != E_OK) {
		fprintf(stderr, "ERROR: Failed to disable Epiphany eLinks\n");
		return rc;
	}

	/* We need to call e_init() to initialize platform data */
	rc = e_init(NULL);
	if (rc != E_OK) {
		fprintf(stderr, "ERROR: Failed to initialize Epiphany "
				"platform.\n");
		return rc;
	}

#if DEBUG
	e_set_host_verbosity(H_D1);
#endif

	/* Ensure we can access the XADC temperature sensor */
	rc = update_temp_sensor(&wd);
	if (rc) {
		perror("ERROR: Temperature sensor sysfs entries not present");
		fprintf(stderr, "Make sure to compile your kernel with"
			" \"CONFIG_IIO=y\" and \"CONFIG_XILINX_XADC=y\".\n");

		goto exit_e_finalize;
	}

	/* Set up SIGTERM handler */
	signal (SIGTERM, sigterm_handler);


	fprintf(stderr, "Entering mainloop.\n");
	rc = mainloop(&wd);
	if (rc) {
		fprintf(stderr, "ERROR: mainloop failed\n");
	} else {
		fprintf(stderr, "Exiting normally\n");
	}

exit_e_finalize:
	e_finalize();

	return rc;

}

// the 'baton' is the carrier for data between functions
struct Baton
{
    // required
    uv_work_t request;                  // libuv
    Persistent<Function> callback;      // javascript callback
};
 
// called by libuv worker in separate thread
static void StartAsync(uv_work_t *req)
{
    Baton *baton = static_cast<Baton *>(req->data);
    start();
}
 
// called by libuv in event loop when async function completes
static void StartAsyncAfter(uv_work_t *req, int status)
{
    // get the reference to the baton from the request
    Baton *baton = static_cast<Baton *>(req->data);
 
    // set up return arguments
    Handle<Value> argv[] = {};
 
    // execute the callback
    baton->callback->Call(Context::GetCurrent()->Global(),0,argv);
 
    // dispose the callback object from the baton
    baton->callback.Dispose();
 
    // delete the baton object
    delete baton;
}
 
// javascript callable function
Handle<Value> StartDaemon(const Arguments &args)
{
    // create 'baton' data carrier
    Baton *baton = new Baton;
 
    // get callback argument
    Handle<Function> cb = Handle<Function>::Cast(args[0]);
 
    // attach baton to uv work request
    baton->request.data = baton;
 
    // assign callback to baton
    baton->callback = Persistent<Function>::New(cb);
 
    // queue the async function to the event loop
    // the uv default loop is the node.js event loop
    uv_queue_work(uv_default_loop(),&baton->request,StartAsync,StartAsyncAfter);
 
    // nothing returned
    return Undefined();
}
 
void init(Handle<Object> exports) {
 
  // add the async function to the exports for this object
  exports->Set(
                String::NewSymbol("start"),                          // javascript function name
                FunctionTemplate::New(StartDaemon)->GetFunction()
              );
}
 
NODE_MODULE(thermald, init)
