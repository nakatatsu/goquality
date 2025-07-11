package calc

// High cohesion example - LCOM4 should be 1
type Calculator struct {
	value  float64
	result float64
}

func (c *Calculator) Add(x float64) {
	c.result = c.value + x
}

func (c *Calculator) Multiply(x float64) {
	c.result = c.value * x
}

func (c *Calculator) GetResult() float64 {
	return c.result
}

// Low cohesion example - LCOM4 should be higher
type MixedService struct {
	database string
	logger   string
	cache    map[string]string
	config   map[string]int
}

func (m *MixedService) ConnectDB() {
	_ = m.database
}

func (m *MixedService) Log(message string) {
	_ = m.logger
}

func (m *MixedService) GetFromCache(key string) string {
	return m.cache[key]
}

func (m *MixedService) GetConfig(key string) int {
	return m.config[key]
}