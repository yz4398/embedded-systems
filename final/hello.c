/*
 * Userspace program that communicates with the vga_ball device driver
 * through ioctls
 *
 * Stephen A. Edwards
 * Columbia University
 */

#include <stdio.h>
#include "vga_ball.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

int vga_ball_fd;

/* Set the background color */
void set_background_color(const vga_ball_pos *c)
{
  vga_ball_arg_t vla;
  vla.position = *c;
  if (ioctl(vga_ball_fd, VGA_BALL_WRITE_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_SET_BACKGROUND) failed");
      return;
  }
}

int main()
{
  vga_ball_arg_t vla;
  int i;
  static const char filename[] = "/dev/vga_ball";
  int x_speed = 10;
  int y_speed = 10;
  int pos_x = 50;
  int pos_y =40;
  int snake_length = 2;
  vga_ball_pos position = { 50, 40, 2};
  
  printf("VGA ball Userspace program started\n");

  if ((vga_ball_fd = open(filename, O_RDWR)) == -1) {
    fprintf(stderr, "could not open %s\n", filename);
    return -1;
  }

   while(1){

     if(pos_x>30&&pos_y<=40&&pos_x<=70) pos_x=pos_x-1;
        else if(pos_x<=30&&pos_y<60) pos_y=pos_y+1;
         else if(pos_x>=30&&pos_y>=60&&pos_x<70) pos_x=pos_x+1; 
          else if(pos_x>=70)  pos_y=pos_y-1;
     position.x = pos_x;
     position.y = pos_y;
     if(pos_x==70&&pos_y==40&&snake_length<=5) position.length++;
     set_background_color(&position);
     usleep(40000);
   }

  return 0;
}
