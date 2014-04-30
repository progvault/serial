#include <stdio.h>       /* Standard input/output definitions */
#include <string.h>      /* String function definitions */
#include <unistd.h>      /* UNIX standard function definitions */
#include <fcntl.h>       /* File control definitions */
#include <errno.h>       /* Error number definitions */
#include <termios.h>     /* POSIX terminal control definitions */
#include <sys/ioctl.h>   /* Serial Port IO Controls */

int fd; /* File descriptor for the port */
struct termios options_original;  /* Original Serial Port Options */

int main()
{
  fd = open_port();
  flush_port();
  write_port();
  printf("FIONBIO value %d\n", FIONBIO);
  usleep(2);
  printf("FIONREAD value %d\n", FIONREAD);
  read_port();
  close_port();
}

/*
 * open_port() - Open serial port 1.
 *
 * Returns the file descriptor on success or -1 on error
 */
int open_port(void)
{
  struct termios options;

  fd = open("/dev/ttyUSB0", O_RDWR | O_NOCTTY | O_NDELAY | O_NONBLOCK);
  if (fd != -1)
  {
    printf("Serial Port Open\n");
    fcntl(fd, F_SETFL, 0);
    tcgetattr(fd, &options_original);
    tcgetattr(fd, &options);
    cfsetispeed(&options, B115200);
    cfsetospeed(&options, B115200);
    options.c_cflag |= (CLOCAL | CREAD); /* Enable the receiver and set local mode */
    options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);  /* Raw Input Mode */
    tcsetattr(fd, TCSANOW, &options);    /* Set the new options for the port */
  }
  else
  {
    /* Could not open the port */
    perror("open_port: Unable to open /dev/ttyUSB0 - ");
  }

  return (fd);
}

int close_port(void)
{
  tcsetattr(fd, TCSANOW, &options_original);
  printf("Serial Port Closed\n");
  close(fd);
}

int flush_port(void)
{
  usleep(2); // required to make flush work, for some reason
  printf("Flushing IO Buffers\n");
  tcflush(fd, TCIOFLUSH);
}

int write_port(void)
{
  int n = write(fd, "DSC", 3);
  if (n < 0)
    fputs("write() of 1 byte failed!\n", stderr);
  else
    printf("Wrote %0d bytes to serial port\n", n);
}

int read_port(void)
{
  int  chars_read = 3;
  int  bytes;
  char read_buffer[3] = {0};
  int  i;

  //fcntl(fd, F_SETFL, 0);
  ioctl(fd, FIONREAD, &bytes);
  printf("Number of bytes = %d\n", bytes);
  int n = read(fd, read_buffer, chars_read);
  printf("Character at Port: %s\n", read_buffer);
  printf("Number of chars read = %0d\n", n);
}
