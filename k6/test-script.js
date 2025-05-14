import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
  vus: 2000, 
  duration: '5m', 
};

export default function () {
  http.get('http://kimdongju.site/api/ping'); 
  sleep(1);
}
