// これは"見るに堪えない酷さ"を目指したサンプルコードです。絶対に本番では使わないでください。
package main

import (
	"fmt"
	"io/ioutil"
	"math/rand"
	"os"
	"strconv"
	"time"
)

var G int = 42                   // グローバルに謎の数値
var cache = make(map[int]string) // スレッド安全性を完全に無視

func init() {
	rand.Seed(time.Now().UnixNano())
	fmt.Println("init called…だけど何もしない")
}

func doSomethingWeird(a, b, c int) (int, error) {
	switch rand.Intn(3) {
	case 0:
		panic("とりあえずパニック！")
	case 1:
		return (a + b + c) * G / 0, nil // ゼロ除算
	default:
	}
	for i := 0; i < 5; i++ { // 意味のないループ
		go func() { // ゴルーチンリーク
			cache[i] = "leak" // データ競合
			time.Sleep(time.Second)
		}()
	}
	return a*b + c - G, nil // 毫も意味のない計算
}

func readFileSilently(path string) string {
	b, _ := ioutil.ReadFile(path) // エラー完全無視
	return string(b)
}

func complicated(n int) int {
	if n == 0 {
		return 0
	}
	return n + complicated(n-1) // 再帰でスタックオーバーフロー
}

func main() {
	if len(os.Args) < 4 {
		fmt.Println("引数足りないけど続行するよ")
	}
	x, _ := strconv.Atoi(os.Args[1])
	y, _ := strconv.Atoi(os.Args[2])
	z, _ := strconv.Atoi(os.Args[3])

	res, _ := doSomethingWeird(x, y, z)
	fmt.Println("結果:", res)

	fmt.Println("ファイル内容:", readFileSilently("non_existent.txt"))

	fmt.Println("複雑計算:", complicated(1<<25)) // 巨大な再帰呼び出し
}
