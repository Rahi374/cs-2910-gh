#include <stdio.h>

#include "darknet/include/darknet.h"

#define DARKNET_DIR ""

void print_usage(char *argv0)
{
	printf("Usage: hello world\n");
}

int main(int argc, char **argv)
{
	char *datacfg    = find_char_arg(argc, argv, "-d", DARKNET_DIR "cfg/coco.data");
	char *cfgfile    = find_char_arg(argc, argv, "-c", DARKNET_DIR "cfg/yolov3.cfg");
	char *weightfile = find_char_arg(argc, argv, "-w", DARKNET_DIR "yolov3.weights");
	char *filename   = find_char_arg(argc, argv, "-f", "");
	char *outfile    = find_char_arg(argc, argv, "-o", "");
	int gpu_index    = find_int_arg(argc, argv, "-i", 0);

	float thresh = 0.5;
	float hier_thresh = 0.5;
	int fullscreen = 0;

	void *cap;

	if (!filename[0]) {
		fprintf(stderr, "Missing input file name.\n");
		print_usage(argv[0]);
		exit(1);
	}

	/* Set GPU. */
	cuda_set_device(gpu_index);

	/* Load name labels. */
	list *options = read_data_cfg(datacfg);
	char *name_list = option_find_str(options, "names", DARKNET_DIR "data/names.list");
	char **names = get_labels(name_list);

	/* I think this is for actually drawing the labels. */
	image **alphabet = load_alphabet();

	/* Load the network (reads from network cfg file). */
	network *net = load_network(cfgfile, weightfile, 0);
	set_batch_network(net, 1);
	srand(9001);

	/*
	 * Open the video feed.
	 * TODO: allow selecting between file and camera, and multiple simultaneous streams
	 */
        cap = open_video_stream(filename, 0, 0, 0, 0);
	if (!cap) {
		fprintf(stderr, "Failed to open video feed %s\n", filename);
		exit(1);
	}

	image img;
	image img_lb;
	layer l;
	float nms = 0.4;
	float fps = 0;
	/* Keep track of the time to measure fps. */
	double last_time = what_time_is_it_now();

	int i = 0;
	while (++i) {
		/* Fetch */
		if (i > 1)
			free_image(img);
		img = get_image_from_stream(cap);
		if (!img.data)
			break;
		img_lb = letterbox_image(img, net->w, net->h);

		/* Detect */
		l = net->layers[net->n-1];
		float *X = img_lb.data;
		network_predict(net, X);

		int nboxes = 0;
		/* TODO: for now use this, but investigate this vs src/demo.c:avg_predictions() */
		detection *dets = get_network_boxes(net, img.w, img.h, thresh, hier_thresh, 0, 1, &nboxes);

		/*
		 * TODO: for now use this, but investigate this vs src/box.c:do_nms_sort()
		 * It looks mostly the same, but sort has another sort? Not sure.
		 */
		if (nms > 0)
			do_nms_obj(dets, nboxes, l.classes, nms);

		printf("\033[2J");
		printf("\033[1;1H");
		printf("\nFPS:%.1f\n", fps);
		printf("Objects:\n\n");
		draw_detections(img, dets, nboxes, thresh, names, alphabet, l.classes);
		free_detections(dets, nboxes);

		/* Print stuff */
		double cur_time = what_time_is_it_now();
		printf("cur_time = %f, last_time = %f\n\n", cur_time, last_time);
		fps = 1.0/(cur_time - last_time);
		last_time = cur_time;
		show_image(img, "Frame", 1);
	}

	return 0;
}
