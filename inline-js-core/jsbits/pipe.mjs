import fs from "fs";
import util from "util";
import { Lock } from "./lock.mjs";

const read_lock = new Lock(),
  write_lock = new Lock(),
  read_func = util.promisify(fs.read),
  write_func = util.promisify(fs.write);

export async function pipeRead(fd, buf, offset, length) {
  await read_lock.take();
  let total_bytes_read = 0;
  while (total_bytes_read < length) {
    const { bytesRead } = await read_func(
      fd,
      buf,
      offset + total_bytes_read,
      length - total_bytes_read,
      null
    );
    total_bytes_read += bytesRead;
  }
  read_lock.put();
}

export async function pipeWrite(fd, buf) {
  await write_lock.take();
  let total_bytes_written = 0;
  while (total_bytes_written < buf.length) {
    const { bytesWritten } = await write_func(
      fd,
      buf,
      total_bytes_written,
      buf.length - total_bytes_written,
      null
    );
    total_bytes_written += bytesWritten;
  }
  write_lock.put();
}
