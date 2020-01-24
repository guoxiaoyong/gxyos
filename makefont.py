import sys

def is_byte_line(line):
  return (len(line) == 8 and
          set(['.', '*']) == set(line) or
          set(['*']) == set(line) or
          set(['.']) == set(line))

def line2byte(line):
  return sum((v == '*') << (7 - idx) for idx, v in enumerate(line))

def main():
  ifile = sys.argv[1]
  ofile = sys.argv[2]

  all_bytes = bytearray(4096)
  idx = 0
  with open(ifile) as ifile:
    for line in ifile:
      line = line.strip()
      if is_byte_line(line):
        all_bytes[idx] = line2byte(line)
        idx += 1

  with open(ofile, 'wb') as ofile:
    ofile.write(all_bytes)


if __name__ == '__main__':
  main()
