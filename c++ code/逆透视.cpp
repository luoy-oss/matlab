#define _CRT_SECURE_NO_WARNINGS


#include <opencv2/opencv.hpp>
#include <opencv2/highgui.hpp>
#include <iostream>
#include <stdio.h>
using namespace std;
using namespace cv;


#define RESULT_ROW 240//结果图行列
#define RESULT_COL 320
#define	USED_ROW	240//用于透视图的行列
#define	USED_COL	320  


int ipts0[320][2];

int main() {
	cout << sizeof(ipts0) / sizeof(ipts0[0]) << endl;
	Mat frame = imread("f (2).jpg");
	Mat nitoushi = Mat::zeros(Size(320, 240), CV_8UC1);
	cvtColor(frame, frame, COLOR_BGR2GRAY);
	threshold(frame, frame, 0, 255, THRESH_OTSU);
	VideoCapture cap(0);
	cap.set(cv::CAP_PROP_FRAME_WIDTH, 320);
	cap.set(cv::CAP_PROP_FRAME_HEIGHT, 240);
	/*while (1) {
		cap >> frame;
		frame = imread("f (2).jpg");
		cvtColor(frame, frame, COLOR_BGR2GRAY);
		threshold(frame, frame, 0, 255, THRESH_OTSU);
		double change_un_Mat[3][3] = { {0.659895,-0.583090,63.912258},{0.040383,0.100722,4.954539},{0.000448,-0.003773,1.017603} };	
		for (int c = 0; c < RESULT_COL; c++) {
			for (int r = 0; r < RESULT_ROW; r++) {
				int j = r;
				int i = c;
				double local_x = mapx[j][i];
				double local_y = mapy[j][i];
				if (local_x >= 0 && local_y >= 0 && local_y < USED_ROW && local_x < USED_COL) {
					if ((int)frame.at<uchar>(local_y, local_x) < 5) {
						circle(nitoushi, Point(c, r), 1, Scalar(0, 0, 0));
					}
					else {
						circle(nitoushi, Point(c, r), 1, Scalar(255, 255, 255));
					}
				}
				else {
					circle(nitoushi, Point(c, r), 1, Scalar(0, 0, 0));
				}
			}
		}

		imshow("透视变换后", nitoushi);
		waitKey(1);
	}*/
	while (1) {
		cap >> frame;
		frame = imread("./10cm.jpg");
		frame = imread("D:\\Tencent\\TIM\\Files\\1\\76.jpg");
		frame = imread("D:\\Program\\Python\\pythonProject\\mp4\\frame\\688.jpg");
		frame = imread("G:\\RUBO_UDIPM\\46.jpg");
		Mat image = frame.clone();
		cvtColor(frame, frame, COLOR_BGR2GRAY);
		threshold(frame, frame, 0, 255, THRESH_OTSU);

	//	double change_un_Mat[3][3] = {
	//		{1.47422610500618	,4.47645916237923 ,- 74.5166977562251 },
	//		{0	,7.89705142204063 ,- 57.4443574876574 },
	//		{0	,0.0278328337660258	,1.00001633949724 },
	//};
		double change_un_Mat[3][3] = { 
			{5.25593833203067	,17.3095406588690, - 649.228791684686 },
		{0.0824945245133797	,31.1167219021136 ,- 929.867553910486 },
		{- 0.000330248767107643	,0.109290944147268	,0.999723435578921 },
	};
		FILE* mapy;
		FILE* mapx;
		mapx = fopen("mapx.txt", "w");
		mapy = fopen("mapy.txt", "w");
		fprintf(mapx, "double mapx[240][320] = {\n");
		fprintf(mapy, "double mapy[240][320] = {\n");

		for (int r = 0; r < USED_ROW; r++) {
			for (int c = 0; c < USED_COL; c++) {
				int j = r;
				int i = c;
				double local_x = (
					(change_un_Mat[0][0] * i + change_un_Mat[0][1] * j + change_un_Mat[0][2])
					/ (change_un_Mat[2][0] * i + change_un_Mat[2][1] * j + change_un_Mat[2][2]));
				double local_y = (
					(change_un_Mat[1][0] * i + change_un_Mat[1][1] * j + change_un_Mat[1][2])
					/ (change_un_Mat[2][0] * i + change_un_Mat[2][1] * j + change_un_Mat[2][2]));

				if ((int)c == 160 && (int)r == 210) {
					cout << c <<","<<r << " : " <<local_x <<"," << local_y << endl;
				}
				if ((int)frame.at<uchar>(r, c) < 5) {
					circle(nitoushi, Point((int)local_x, (int)local_y), 1, Scalar(0, 0, 0));
				}
				else {
					circle(nitoushi, Point((int)local_x, (int)local_y), 1, Scalar(255, 255, 255));
				}
				fprintf(mapx, "%lf,", local_x);
				fprintf(mapy, "%lf,", local_y);
				
				if (local_y < 0) {

				//std::cout << Point(local_x, local_y) << std::endl;
				}
			}
			fprintf(mapx, "\n");
			fprintf(mapy, "\n");
		}
		fprintf(mapx, "};\n");
		fprintf(mapy, "};\n");

		fclose(mapx);
		fclose(mapy);

		imshow("原图", image);
		imshow("二值化图像", frame);
		imshow("透视变换后", nitoushi);
		imwrite("f.jpg", nitoushi);
		/*string f = "";
		string b = "";
		static int i = 1;
		f = "../img/f" + to_string(i++) + ".jpg";
		b = "../img/b" + to_string(i++) + ".jpg";
		imwrite(f, image);
		imwrite(b, frame);*/
		waitKey(3000);
		break;
	}
	return 0;
}

